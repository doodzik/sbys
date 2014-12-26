require 'sbys/version'
require 'enumerator_concurrent'

module Sbys
  class Caller
    def initialize(ast, lambdas)
      @ast = ast
    end

    def call
      @ast.map do |meths|
        meths.concurrent.threads(3).map do |meth|
          if meth.is_a? Hash
            name = meth.keys[0]
            params = meth[name].map { |param| { param => lambdas[param] } }
            lambdas[name] = lambdas[name].call(**params)
          else
            lambdas[name] = lambdas[meth].call
          end
        end
      end
    end
  end

  class Sbys
    attr_reader :ast
    attr_reader :lambdas

    def initialize(callee: Caller, **args)
      @callee = callee
      @ast = args.empty? ? [] : args.keys
      @lambdas = args.empty? ? {} : args
      @sorted = false
    end

    def call
      sort_ast
      @callee.new(@ast, @lambdas).call
    end

    def sort_ast
      unless @sorted
        symbols, hashes = [@ast.clone, @ast.clone]
        symbols.delete_if {|value| value.is_a? Hash }
        hashes.delete_if {|value| value.is_a? Symbol }
        @ast = symbols
        _sort_ast(hashes, symbols.clone)
        @sorted = true
      end
    end

    def method_missing(meth, *args, &block)
      meth = meth.to_s
      if meth =~ /=$/
        meth[-1] = ''
        meth = meth.to_sym
        raise StandardError if @lambdas.keys.include?(meth)
        params = args[0].parameters
        @sorted = false
        if !params.empty?
          params = params.flatten.reject { |a| a == :keyreq }
          @ast << { meth => params }
        else
          @ast << meth
        end
        @lambdas[meth] = args[0]
      end
    end

  private

  def _sort_ast(hashes, symbols)
    while !hashes.empty?
      _arr, new_symbols, hashes_to_delete = [], [], []
      hashes.each do |hash|
        meth = hash.keys[0]
        params = hash[meth.to_sym]
          if params.all? { |param| symbols.include?(param) }
            new_symbols << meth
            _arr << { meth => params }
            hashes_to_delete << meth
          end
        end
        hashes.reject! { |h| hashes_to_delete.include?(h.keys[0]) }
        symbols = symbols.concat(new_symbols)
        @ast.push(_arr)
      end
    end
  end
end
