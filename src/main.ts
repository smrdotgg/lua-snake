import "./style.css";
import typescriptLogo from "./typescript.svg";
import viteLogo from "/vite.svg";
import { setupCounter } from "./counter.ts";

document.querySelector<HTMLDivElement>("#app")!.innerHTML = `
  <div>
    <a href="https://vite.dev" target="_blank">
      <img src="${viteLogo}" class="logo" alt="Vite logo" />
    </a>
    <a href="https://www.typescriptlang.org/" target="_blank">
      <img src="${typescriptLogo}" class="logo vanilla" alt="TypeScript logo" />
    </a>
    <h1>Vite + TypeScript</h1>
    <div class="card">
      <button id="counter" type="button"></button>
    </div>
    <p class="read-the-docs">
      Click on the Vite and TypeScript logos to learn moreee
    </p>
    <script src="https://daurnimator.github.io/lua.vm.js/lua.vm.js"></script>

<script type="text/lua">
js.global:alert('hello from Lua script tag in HTML!') -- this is Lua!

</script>
  </div>
`;

setupCounter(document.querySelector<HTMLButtonElement>("#counter")!);
