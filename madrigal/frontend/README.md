# Frontend

A React app built with [Vite](https://vitejs.dev/).

## Available Scripts

In the project directory, you can run:

### `npm run dev` (alias: `npm start`)

Runs the app in development mode with Vite's dev server.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page reloads instantly on changes via Vite's HMR.

### `npm test`

Runs the test suite once with [Vitest](https://vitest.dev/).

### `npm run build`

Builds the app for production into the `build` folder (this path is fixed
in `vite.config.js` to match what `madrigal/build.gradle.kts`'s
`buildReact`/`copyReactBuild` Gradle tasks expect).

### `npm run preview`

Serves the production build from `build/` locally, for a final check before
deploying.

## Learn More

- [Vite documentation](https://vitejs.dev/guide/)
- [React documentation](https://react.dev/)
