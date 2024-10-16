import { build } from 'esbuild';

build({
  entryPoints: ['src/task.js'],
  banner: {js:"import { createRequire } from 'module';const require = (m) => { if (m === './reserved.js') return {}; return createRequire(import.meta.url)(m);};const __dirname='.';"},
  bundle: true,
  outfile: './dist/task.mjs',
  platform: 'node',
  format: 'esm',
  minify: false,
  external: [],
  define: {
    'process.env.NODE_ENV': '"production"',
  }
})
.then(() => console.log('⚡ Done'))
.catch((error) => {
  throw error;
});