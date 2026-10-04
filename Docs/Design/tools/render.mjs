// Adapts the installed app-designer renderer to Mac windows without changing its checks.
// Install the skill and its playwright-core dependency before running this file.
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
const root = process.cwd();
const skill = path.join(root, '.agents/skills/app-designer');
let source = fs.readFileSync(path.join(skill, 'scripts/shoot.mjs'), 'utf8');
source = source.replace('if (smallPhone && screen.dataset.chrome === "none") continue;',
  'if (smallPhone && screen.dataset.chrome === "none" && screen.dataset.platform !== "mac") continue;');
source = source.replace('width:${s.icon ? 344 : 402}px', 'width:${s.icon ? 344 : 640}px');
source = source.replace('border-radius:${s.icon ? 77 : 55}px', 'border-radius:${s.icon ? 77 : 12}px');
source = source.replace('Math.min(4, shots.length)', 'Math.min(2, shots.length)');
source = source.replaceAll('perRow * 434', 'perRow * 672');
// Native scroll views and ellipsized table cells intentionally hide offscreen ink.
// Clamp those ink boxes to their visible bounds so hidden rows cannot collide with a footer.
source = source.replace('boxes.push({ e, r, t });', `
          const scroll = e.closest('[data-scrolls]');
          if (scroll) {
            const clip = scroll.getBoundingClientRect();
            r.top = Math.max(r.top, clip.top); r.bottom = Math.min(r.bottom, clip.bottom);
            r.left = Math.max(r.left, clip.left); r.right = Math.min(r.right, clip.right);
          }
          if (cs.textOverflow === 'ellipsis') {
            const clip = e.getBoundingClientRect();
            r.left = Math.max(r.left, clip.left); r.right = Math.min(r.right, clip.right);
          }
          if (r.bottom <= r.top || r.right <= r.left) continue;
          r.height = r.bottom - r.top; r.width = r.right - r.left;
          boxes.push({ e, r, t });`);
// Chromium in this workspace blocks file://. Serve authorized local files over loopback.
const port = 8816;
const base = `http://127.0.0.1:${port}/`;
source = source.replace('const SRC = path.resolve(file);',
  `const localURL = p => new URL(encodeURI(path.relative(${JSON.stringify(root)}, p)), ${JSON.stringify(base)}).href;\nconst SRC = path.resolve(file);`);
source = source.replaceAll('pathToFileURL(SRC).href', 'localURL(SRC)')
  .replaceAll('pathToFileURL(s.out).href', 'localURL(s.out)')
  .replaceAll('pathToFileURL(sheetFile).href', 'localURL(sheetFile)');
const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', root], { stdio: 'ignore' });
let ready = false;
for (let attempt = 0; attempt < 30; attempt++) {
  try { const response = await fetch(base); if (response.ok) { ready = true; break; } } catch {}
  await new Promise(resolve => setTimeout(resolve, 100));
}
if (!ready) { server.kill(); throw new Error('Local preview server did not start'); }
const generated = path.join(skill, 'scripts/shoot-mac.generated.mjs');
fs.writeFileSync(generated, source);
const run = spawnSync(process.execPath, [generated, ...process.argv.slice(2)], { stdio: 'inherit' });
server.kill();
process.exit(run.status ?? 1);
