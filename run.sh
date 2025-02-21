export DATABASE_URL=postgresql://yamansarabariya:helloworld@localhost:5432/blockscout
export ETHEREUM_JSONRPC_VARIANT=geth 
export ETHEREUM_JSONRPC_HTTP_URL=http://localhost:8545
export API_V2_ENABLED=true
export PORT=3001 # set for local API usage
export COIN=yourcoin
export COIN_NAME=yourcoinname
export DISPLAY_TOKEN_ICONS=true
export CHAIN_TYPE=twine
mix do ecto.create, ecto.migrate
mix phx.server