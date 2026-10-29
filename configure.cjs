const fs = require('fs');
const path = require('path');
const file = path.join(process.env.HOME, '.openclaw/openclaw.json');
const config = JSON.parse(fs.readFileSync(file, 'utf8'));
const model = process.argv[1] || 'qwen3.5:9b';
const context = Number(process.argv[2] || 32768);
const baseUrl = 'http://host.openshell.internal:11434';
config.models = { mode: 'merge', providers: { ollama: {
  baseUrl,
  api: 'ollama', apiKey: 'ollama-local',
  models: [{ id: model, name: model, reasoning: false,
    input: ['text'], contextWindow: context, contextTokens: context, maxTokens: 2048,
    params: { num_ctx: context, thinking: false },
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } }]
}}};
config.agents.defaults.model = { primary: 'ollama/' + model };
delete config.agents.defaults.memorySearch;
config.agents.defaults.thinkingDefault = 'off';
config.env = { vars: { OLLAMA_API_KEY: 'ollama-local' } };
fs.writeFileSync(file, JSON.stringify(config, null, 2), {mode: 0o600});
console.log('Configured local Ollama model.');
