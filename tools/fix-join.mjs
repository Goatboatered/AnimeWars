import fs from 'fs';

const filepath = process.argv[2] || 'tools/fetch-swarfarm.mjs';
let c = fs.readFileSync(filepath, 'utf8');

// Fix broken join() calls where a literal newline was embedded inside the string:
//   ...join("
//   ");
// Merge those into: ...join("\n");
// Works with both LF and CRLF files.

const lines = c.split('\n').map(l => l.replace(/\r$/, ''));
const fixed = [];
let count = 0;
let i = 0;
while (i < lines.length) {
    const line = lines[i];
    const next = i + 1 < lines.length ? lines[i + 1].trim() : null;
    if ((line.endsWith('.join("') || line.endsWith('].join("')) && next === '");') {
        fixed.push(line + '\\n");');
        i += 2;
        count++;
        console.log('  Fixed join at original line', i - 1);
    } else {
        fixed.push(line);
        i++;
    }
}

// Detect original line ending
const crlf = c.includes('\r\n');
const result = fixed.join(crlf ? '\r\n' : '\n');
fs.writeFileSync(filepath, result, 'utf8');
console.log(`Fixed ${count} join(s) in ${filepath} (${crlf ? 'CRLF' : 'LF'})`);
