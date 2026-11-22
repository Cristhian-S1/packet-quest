class_name PasswordLogic
extends RefCounted

enum Symbol { TRIANGLE, CIRCLE, STAR, SQUARE }

const SOLUTION: Array[Symbol] = [Symbol.TRIANGLE, Symbol.CIRCLE, Symbol.STAR, Symbol.SQUARE]
const INITIAL: Array[Symbol] = [Symbol.CIRCLE, Symbol.STAR, Symbol.SQUARE, Symbol.TRIANGLE]

static func cycle(symbol: int) -> int:
	return (symbol + 1) % 4

static func index_of(code: Array, symbol: int) -> int:
	return code.find(symbol)

static func circle_before_star(code: Array) -> bool:
	return index_of(code, Symbol.CIRCLE) + 1 == index_of(code, Symbol.STAR)

static func triangle_before_square(code: Array) -> bool:
	return index_of(code, Symbol.TRIANGLE) < index_of(code, Symbol.SQUARE)

static func circle_not_first(code: Array) -> bool:
	return index_of(code, Symbol.CIRCLE) != 0

static func star_not_last(code: Array) -> bool:
	return index_of(code, Symbol.STAR) != 3

static func is_permutation(code: Array) -> bool:
	return code.size() == SOLUTION.size() and code.has(Symbol.TRIANGLE) and code.has(Symbol.CIRCLE) \
		and code.has(Symbol.STAR) and code.has(Symbol.SQUARE)

static func is_solution(code: Array) -> bool:
	return is_permutation(code) and circle_before_star(code) and triangle_before_square(code) \
		and circle_not_first(code) and star_not_last(code)
