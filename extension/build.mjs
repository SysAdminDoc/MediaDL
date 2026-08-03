import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const extensionRoot = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.dirname(extensionRoot);
const sourcePath = path.join(repoRoot, 'MediaDL.user.js');
const bridgePath = path.join(extensionRoot, 'shared', 'bridge.js');
const backgroundPath = path.join(extensionRoot, 'shared', 'background.js');
const edgeBackgroundPath = path.join(extensionRoot, 'shared', 'edge-background.js');
const source = fs.readFileSync(sourcePath, 'utf8');
const marker = '// ==/UserScript==';
const markerIndex = source.indexOf(marker);
if (markerIndex < 0) throw new Error('Userscript metadata marker not found');

const bridge = fs.readFileSync(bridgePath, 'utf8').trim();
const background = fs.readFileSync(backgroundPath, 'utf8');
const edgeBackground = fs.readFileSync(edgeBackgroundPath, 'utf8');
const content = `${bridge}\n\n${source.slice(markerIndex + marker.length).trimStart()}`;

for (const variant of ['chrome', 'firefox', 'edge']) {
    const variantRoot = path.join(extensionRoot, variant);
    fs.mkdirSync(variantRoot, { recursive: true });
    fs.writeFileSync(path.join(variantRoot, 'content.js'), `${content}\n`, 'utf8');
    fs.writeFileSync(path.join(variantRoot, 'background.js'), variant === 'edge' ? `${background}\n\n${edgeBackground}` : background, 'utf8');
}

console.log('Built Chrome, Firefox, and Edge MV3 content/background adapters from MediaDL.user.js');
