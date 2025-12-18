import { AgentRuntime, Memory, State, elizaLogger } from "@elizaos/core";
import { DirectClient } from "@elizaos/client-direct";
import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  elizaLogger.log("Starting Yieldra AI Agent...");

  // Load character configuration
  const characterPath = path.join(__dirname, "../character.json");
  const characterData = JSON.parse(fs.readFileSync(characterPath, "utf-8"));

  // Create agent runtime
  const runtime = new AgentRuntime({
    character: characterData,
    modelProvider: process.env.MODEL_PROVIDER || "openai",
    evaluators: [],
    actions: [],
    providers: [],
    plugins: [],
  });

  // Initialize runtime
  await runtime.initialize();

  elizaLogger.log("Yieldra Agent initialized successfully");
  elizaLogger.log(`Agent Name: ${runtime.character.name}`);
  elizaLogger.log(`Agent Username: ${runtime.character.username}`);

  // Create direct client for interaction
  const client = new DirectClient({
    runtime,
  });

  // Start the agent
  elizaLogger.log("Starting agent client...");
  await client.start();

  elizaLogger.log("Yieldra Agent is running and ready to optimize yield!");
  elizaLogger.log("The agent will continuously monitor protocols and propose rebalancing strategies.");
}

main().catch((error) => {
  elizaLogger.error("Failed to start agent:", error);
  process.exit(1);
});
