# Load environment variables from .env files
if Code.ensure_loaded?(Dotenv) do
  # Load .env.local if it exists (for local overrides)
  if File.exists?(".env.local") do
    Dotenv.load!(".env.local")
  end

  # Load environment-specific env file if it exists
  env_file = ".env.#{Mix.env()}"

  if File.exists?(env_file) do
    Dotenv.load!(env_file)
  end

  # Load default .env file if it exists
  if File.exists?(".env") do
    Dotenv.load!(".env")
  end
end
