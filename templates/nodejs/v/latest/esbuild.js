import { build } from 'esbuild';

build({
  entryPoints: ['src/index.js'],
  bundle: true,
  outdir: './dist/',
  platform: 'node',
  minify: false,
  external: ['@aws-sdk/*'],
})
.then(() => console.log('⚡ Done'))
.catch((error) => {
  throw error;
});
