# MOTO_TAGS: demo

assert(!const('db_host').nil?, 'Env specific param should not be nil.')
assert(!const('db_port').nil?, 'Common env param should not be nil.')

logger.info "DB: #{const('db_host')}:#{const('db_port')}"
logger.info "Nested param: #{const('nested.example.key')}"
