import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const css=fs.readFileSync(path.join(root,'src/styles.css'),'utf8');
const cta=fs.readFileSync(path.join(root,'src/businessCaseCta.js'),'utf8');

const requiredCss=[
  '.recommendations-section>.grid{grid-template-columns:repeat(3,minmax(0,1fr))',
  '@media(max-width:980px){.recommendations-section>.grid{grid-template-columns:repeat(2,minmax(0,1fr))',
  '@media(max-width:760px)',
  '.recommendations-section>.grid{grid-template-columns:1fr}',
  '.recommendation-actions{display:grid',
  '.recommendation-card{display:flex;flex-direction:column',
  '.composer{align-items:stretch',
  ':focus-visible'
];
const requiredJs=[
  "section.classList.add('recommendations-section')",
  "card.classList.add('recommendation-card')",
  "actions.className='recommendation-actions'",
  "product.classList.add('review-evidence-link')",
  "actions.append(wrap)"
];

const missing=[...requiredCss.filter(x=>!css.includes(x)),...requiredJs.filter(x=>!cta.includes(x))];
if(missing.length){
  console.error('Consultation UI regression contract failed. Missing:');
  missing.forEach(x=>console.error(' - '+x));
  process.exit(1);
}
console.log('Consultation UI regression contract passed.');
