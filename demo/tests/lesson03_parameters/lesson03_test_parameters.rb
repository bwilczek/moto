# MOTO_TAGS: demo, regression
# run command: bundle exec ruby ..\bin\moto run -gdemo -etest,dev
# see yml file in current directory to learn more

assert_equal(@params['a']+@params['b'], @params['sum'])
