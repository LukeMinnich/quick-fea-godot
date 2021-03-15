# This singleton dispatches messages when changes to the FEA Model are issued.
extends Node

var _pending: ModelChangeTransaction
var _undo_history := Stack.new()
var _redo_history := Stack.new()


func send_single(message: ModelChangeMessage) -> void:
	check_for_pending()
	
	print("Message kind: ", message._kind)
	print("Message payload text: ", message._payload.text)
	
	_pending = ModelChangeTransaction.from_single(message)


func send_many(messages: Array) -> void:
	check_for_pending()
	
	for message in messages:
		print("Message kind: ", message._kind)
		print("Message payload text: ", message._payload.text)
	
	_pending = ModelChangeTransaction.from_many(messages)


func check_for_pending():
	if _pending:
		push_error("there was already an transaction in progress")


func execute_pending() -> bool:
	var success = transaction.do()
	if success:
		_undo_history.push(transaction)
		return true
	else:
		return false
