#!/usr/bin/env node
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 鉄道帝国 駅員キャラクター本生成ツール（Leonardo.ai版）
// レア度(N/R/SR/SSR) × アーキタイプ3種のバリエーションを生成する。
// leonardo-ai-image-gen スキルの「決定的バリエーション選択」パターンを流用:
// 同じ入力は常に同じ見た目になるよう、staffIDのハッシュでアーキタイプを選ぶ。
//
// 使い方:
//   node generate_staff.js --all
//   node generate_staff.js --ids n_1,r_1
//   node generate_staff.js --all --force
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const OUTPUT_DIR = path.join(__dirname, 'output', 'staff');
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';

const NEGATIVE_PROMPT = [
  'text, words, letters, numbers, watermark, signature',
  'logo, stamps, seals',
  'ugly, blurry, low quality, deformed, mutated, malformed',
  'extra limbs, bad anatomy, extra fingers',
  'duplicate, oversaturated, washed out',
].join(', ');

// 人型アーキタイプ5種（Card Crownの「人型5+非人型5」パターンを、鉄道帝国では
// 全員人間の駅員なので性格・年齢層のバリエーションに読み替えたもの）
const ARCHETYPES = [
  'a warm dignified middle-aged male station attendant with a gentle smile',
  'a cheerful energetic young female station attendant with a bright welcoming smile',
  'a calm stoic senior stationmaster with a composed authoritative expression',
  'an enthusiastic young male attendant wearing glasses, eager and friendly expression',
  'an elegant composed middle-aged female supervisor with a professional confident expression',
];

// レア度別の背景・演出強度（上位レアほど背景が壮大・光の演出が増える）
const RARITY_CONFIG = {
  N: {
    label: 'N',
    count: 2,
    styleSuffix:
      'simple plain soft gradient background, standard clean navy-blue railway uniform, no extra ornamentation',
  },
  R: {
    label: 'R',
    count: 3,
    styleSuffix:
      'soft blurred train platform background, neat railway uniform with subtle silver trim, gentle rim lighting',
  },
  SR: {
    label: 'SR',
    count: 3,
    styleSuffix:
      'dynamic background with faint railway track motifs and a small train silhouette, glowing soft blue highlights, railway uniform with gold trim accents, slightly dramatic lighting',
  },
  SSR: {
    label: 'SSR',
    count: 2,
    styleSuffix:
      'grand ornate background with golden light rays and sparkling particle effects, elaborate ceremonial railway uniform with rich gold braid, dramatic premium lighting, highly detailed quality game character art',
  },
};

function pickVariant(list, seedKey) {
  let hash = 0;
  for (let i = 0; i < seedKey.length; i++) {
    hash = (hash * 31 + seedKey.charCodeAt(i)) >>> 0;
  }
  return list[hash % list.length];
}

function buildStaffList() {
  const staff = [];
  for (const [rarity, config] of Object.entries(RARITY_CONFIG)) {
    for (let i = 1; i <= config.count; i++) {
      const id = `${rarity.toLowerCase()}_${i}`;
      const archetype = pickVariant(ARCHETYPES, `${id}_${rarity}`);
      const prompt = `A single character illustration: ${archetype}, wearing a Japanese train station staff uniform, rounded approachable game-character proportions, standing confident pose, ${config.styleSuffix}, no text, no logo, no watermark, no border, no signature, semi-realistic mobile game character art style`;
      staff.push({ id, rarity, archetype, prompt });
    }
  }
  return staff;
}

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
  const allStaff = buildStaffList();
  console.log(`📋 駅員定義を ${allStaff.length} 件生成しました（N:${RARITY_CONFIG.N.count} R:${RARITY_CONFIG.R.count} SR:${RARITY_CONFIG.SR.count} SSR:${RARITY_CONFIG.SSR.count}）`);

  let target;
  if (opts.ids) {
    target = allStaff.filter((s) => opts.ids.includes(s.id));
  } else if (opts.all) {
    target = allStaff;
  } else {
    target = allStaff.slice(0, 2);
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

  for (const s of toGenerate) {
    process.stdout.write(`  ${s.id} (${s.rarity}) ... `);
    try {
      const imageUrl = await generateImage(s.prompt, NEGATIVE_PROMPT);
      const outFile = path.join(OUTPUT_DIR, `${s.id}.png`);
      await downloadTo(imageUrl, outFile);
      manifest[s.id] = {
        rarity: s.rarity,
        archetype: s.archetype,
        file: `${s.id}.png`,
        prompt: s.prompt,
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
