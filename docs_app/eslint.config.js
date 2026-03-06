import { a11y, base, imports } from "@leancodepl/eslint-config";
import nextConfig from "eslint-config-next";

export default [
  {
    ignores: ["node_modules", ".next", "out", "build", ".source", "next-env.d.ts"],
  },
  ...base,
  ...imports,
  ...a11y,
  ...nextConfig.flat,
];
