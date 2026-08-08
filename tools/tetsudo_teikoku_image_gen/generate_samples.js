#!/usr/bin/env node
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 鉄道帝国 サンプル画像一括生成ツール（Leonardo.ai版）
// leonardo-ai-image-gen スキルの generate_leonardo.template.js を流用。
// 駅前景観4種+駅員キャラ3種のサンプルを生成し、世界観トーンを確認する。
//
// 使い方:
//   node generate_samples.js --all
//   node generate_samples.js --ids station_none,station_onsen
//   node generate_samples.js --all --force
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const OUTPUT_DIR = path.join(__dirname, 'output');
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';

const NEGATIVE_PROMPT = [
  'text, words, letters, numbers, watermark, signature',
  'logo, stamps, seals',
  'ugly, blurry, low quality, deformed, mutated, malformed',
  'extra limbs, bad anatomy, extra fingers',
  'duplicate, oversaturated, washed out',
].join(', ');

const ART_STYLE =
  'realistic yet warm and inviting mobile game art style, soft painterly shading, clean semi-realistic Japanese railway management game asset illustration, no text, no logo, no watermark, no border, no signature, no stamps, no seals';

const SAMPLES = [
  {
    id: 'station_none',
    label: '駅前景観(未発展)',
    prompt: `A single Japanese train station front townscape illustration, undeveloped ordinary local station: modest station building with wooden platform roof, simple shopping street lined with a few small local shops, quiet residential streets nearby, gentle morning light, muted natural color palette (soft blues, warm beige, gentle greens), wide establishing shot, no people in foreground, ${ART_STYLE}`,
  },
  {
    id: 'station_onsen',
    label: '駅前景観(温泉)',
    prompt: `A single Japanese train station front townscape illustration, onsen (hot spring) development: traditional wooden ryokan inns with steaming hot spring baths, red lanterns lining a cobblestone street, gentle steam rising, warm orange-amber evening light, Japanese hot spring town atmosphere, warm color palette (deep orange, amber, warm brown), wide establishing shot, no people in foreground, ${ART_STYLE}`,
  },
  {
    id: 'station_shogyo',
    label: '駅前景観(商業)',
    prompt: `A single Japanese train station front townscape illustration, shogyo (commercial) development: bustling shopping arcade with covered shotengai street, bright shop signs and awnings, department store facade, lively daytime energy, vivid but tasteful color palette (fresh green accents, bright white, cheerful yellow), wide establishing shot, no distinct human figures, ${ART_STYLE}`,
  },
  {
    id: 'station_kanko',
    label: '駅前景観(観光)',
    prompt: `A single Japanese train station front townscape illustration, kanko (tourism) development: scenic landmark plaza with a traditional Japanese landmark (temple gate or scenic viewpoint), cherry blossom trees, clear blue sky, picturesque sightseeing destination atmosphere, vivid color palette (sakura pink, sky blue, fresh green), wide establishing shot, no people in foreground, ${ART_STYLE}`,
  },
  {
    id: 'staff_sample_1',
    label: '駅員キャラ(男性・ベテラン)',
    prompt: `A single character illustration: a friendly middle-aged Japanese train station staff member, warm dignified smile, neat navy-blue railway uniform with cap and gold buttons, rounded approachable game-character proportions, standing confident pose, simple soft gradient background, no text, no logo, no watermark, no border, no signature, semi-realistic mobile game character art style`,
  },
  {
    id: 'staff_sample_2',
    label: '駅員キャラ(女性・若手)',
    prompt: `A single character illustration: a cheerful young Japanese female train station staff member, bright welcoming smile, neat navy-blue railway uniform with skirt and cap, short bob hairstyle, rounded approachable game-character proportions, energetic pose with one hand raised in greeting, simple soft gradient background, no text, no logo, no watermark, no border, no signature, semi-realistic mobile game character art style`,
  },
  {
    id: 'staff_sample_3',
    label: '駅員キャラ(駅長)',
    prompt: `A single character illustration: a dignified Japanese station master, formal dark navy uniform with more elaborate gold braid and a peaked cap, calm authoritative expression, holding a signal baton, rounded approachable game-character proportions, standing dignified pose, simple soft gradient background, no text, no logo, no watermark, no border, no signature, semi-realistic mobile game character art style`,
  },
];

async function generateImage(prompt, negativePrompt) {
  const createRes = await fetch(`${API_BASE}/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LEONARDO_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      negative_prompt: negativePrompt,
      modelId: LEONARDO_MODEL_ID,
      width: 512,
      height: 512,
      num_images: 1,
      alchemy: false,
      photoReal: false,
    }),
  });

  if (!createRes.ok) {
    throw new Error(`Leonardo API error (create): ${createRes.status} ${await createRes.text()}`);
  }

  const created = await createRes.json();
  const genId = created?.sdGenerationJob?.generationId;
  if (!genId) {
    throw new Error(`generationId が取得できませんでした: ${JSON.stringify(created)}`);
  }

  let attempts = 0;
  let images = null;
  while (attempts < 30) {
    await new Promise((r) => setTimeout(r, 2000));
    const poll = await fetch(`${API_BASE}/generations/${genId}`, {
      headers: { Authorization: `Bearer ${LEONARDO_API_KEY}` },
    });
    if (!poll.ok) {
      throw new Error(`Leonardo API error (poll): ${poll.status} ${await poll.text()}`);
    }
    const data = await poll.json();
    const gen = data.generations_by_pk;
    if (gen?.status === 'COMPLETE') {
      images = gen.generated_images;
      break;
    }
    if (gen?.status === 'FAILED') {
      throw new Error(`generation failed: ${JSON.stringify(gen)}`);
    }
    attempts++;
  }

  if (!images || !images[0]?.url) {
    throw new Error('画像生成がタイムアウトしました');
  }

  return images[0].url;
}

async function downloadTo(url, filePath) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download failed: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filePath, buf);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { ids: null, all: false, force: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--ids') opts.ids = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--all') opts.all = true;
    else if (args[i] === '--force') opts.force = true;
  }
  return opts;
}

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    process.exit(1);
  }

  const opts = parseArgs();
  let target;
  if (opts.ids) {
    target = SAMPLES.filter((s) => opts.ids.includes(s.id));
  } else if (opts.all) {
    target = SAMPLES;
  } else {
    target = SAMPLES.slice(0, 2);
  }

  if (target.length === 0) {
    console.error('❌ 対象が見つかりません');
    process.exit(1);
  }

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const manifestPath = path.join(OUTPUT_DIR, 'manifest.json');
  const manifest = fs.existsSync(manifestPath)
    ? JSON.parse(fs.readFileSync(manifestPath, 'utf8'))
    : {};

  let skipped = 0;
  const toGenerate = opts.force
    ? target
    : target.filter((s) => {
        const exists = fs.existsSync(path.join(OUTPUT_DIR, `${s.id}.png`));
        if (exists) skipped++;
        return !exists;
      });

  if (skipped > 0) {
    console.log(`⏭️  既存の${skipped}枚をスキップ（再生成するには --force を付けてください）`);
  }
  console.log(`🎨 ${toGenerate.length} 枚を生成します（Leonardo.ai / modelId=${LEONARDO_MODEL_ID} / alchemy=off / 512x512）\n`);

  for (const sample of toGenerate) {
    process.stdout.write(`  ${sample.id} (${sample.label}) ... `);
    try {
      const imageUrl = await generateImage(sample.prompt, NEGATIVE_PROMPT);
      const outFile = path.join(OUTPUT_DIR, `${sample.id}.png`);
      await downloadTo(imageUrl, outFile);
      manifest[sample.id] = {
        label: sample.label,
        file: `${sample.id}.png`,
        prompt: sample.prompt,
        provider: 'leonardo',
        modelId: LEONARDO_MODEL_ID,
        generatedAt: new Date().toISOString(),
      };
      fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      console.log('✅');
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }
  }

  console.log(`\n完了（生成${toGenerate.length}枚 / スキップ${skipped}枚）。出力先: ${OUTPUT_DIR}`);
}

main().catch((e) => {
  console.error(`❌ 予期しないエラー: ${e.message}`);
  process.exit(1);
});
