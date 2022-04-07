const chalk = require("chalk");

const msg = `
Welcome to the ${chalk.blue.bold("Uni")} ${chalk.green.bold(
  "Brahma"
)}${chalk.red.bold("Unimobile")} Starter!

For more details, go ${chalk.bold("https://www.brillium.tech/unibrahma")}
`.trim();

console.log(msg);
console.log(JSON.stringify(msg));
