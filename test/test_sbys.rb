require 'minitest/autorun'
require 'sbys'

class CustomCaller
  def initialize(ast, lambdas)
    @ast = ast
  end

  def call
    'called'
  end
end

class SbysTest < Minitest::Test
  def test_var_assignment
    sbys = Sbys::Sbys.new
    sbys.hello = -> { 'world' }
    sbys.world = -> { 'hello' }
    assert_equal([:hello, :world], sbys.lambdas.keys )
    begin
      sbys.hello = -> { 'foo' }
    rescue StandardError => e
      assert(true)
    else
      assert(false)
    end
  end

  def test_ast_building
    sbys = Sbys::Sbys.new
    sbys.hello = -> { 'world' }
    sbys.world = -> { 'hello' }
    sbys.echo  = -> (hello:, world:) { world +' '+hello }
    sbys.echo2 = -> (foo:, world:) { world +' '+foo }
    sbys.foo   = -> { 'foo' }
    sbys.echo3 = -> (echo:, world:) { 'hhuuhuh' }
    assert_equal([:hello, :world, :foo,
                  { echo: [:hello, :world] },
                  { echo2: [:foo, :world  ] },
                  { echo3: [:echo, :world] }
                ].sort_by {|sym| sym.to_s}, sbys.ast.sort_by {|sym| sym.to_s} )
  end

  def test_sort_ast
      sbys = Sbys::Sbys.new
      default = [ :hello, :world, :foo,
        { echo: [:hello, :world] },
        { echo2: [:foo, :world  ] },
        { echo3: [:echo, :world] }
      ]
      sbys.instance_variable_set(:@ast, default)
      sbys.send(:sort_ast)
      ast = sbys.ast
      assert_equal(default[0...3], ast[0..2])
      assert_equal(default[3..4], ast[3])
      assert_equal([default[5]], ast[4])
  end

  def test_set_dependencies
    sbys = Sbys::Sbys.new(Dep1: 'foo', Dep2: 'bar')
    assert_equal([:Dep1, :Dep2], sbys.ast)
    assert_equal({Dep1: 'foo', Dep2: 'bar'}, sbys.lambdas)
  end

  def test_set_caller
    sbys = Sbys::Sbys.new(callee: CustomCaller)
    assert_equal('called', sbys.call)
  end
end
