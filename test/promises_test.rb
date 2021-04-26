# frozen_string_literal: true

require 'test_helper'

class PromisesTest < ActiveSupport::TestCase
  test 'should retrun value as expected' do
    future = ConcurrentRails::Promises.future { 42 }

    assert_equal(future.value, 42)
  end

  test 'should chain futures with `then`' do
    future = ConcurrentRails::Promises.future { 42 }.then { |v| v * 2 }

    assert_equal(future.value, 84)
  end

  test 'should chain futures with `then` and args' do
    future = ConcurrentRails::Promises.
             future { 42 }.
             then(4) { |v, args| (v * 2) - args }

    assert_equal(future.value, 80)
  end

  test 'should accept `then` argument' do
    future = ConcurrentRails::Promises.
             future { 42 }.
             then(2) { |v, arg| (v * 2) + arg }

    assert_equal(future.value!, 86)
  end

  test 'should accept `future` argument' do
    future = ConcurrentRails::Promises.
             future(2) { |v| v * 3 }.
             then { |v| v * 2 }

    assert_equal(future.value!, 12)
  end

  test 'should accept `future` and `then` argument' do
    future = ConcurrentRails::Promises.
             future(2) { |v| v * 2 }.
             then(5) { |v, arg| v * arg }

    assert_equal(future.value!, 20)
  end

  test 'should return timeout value when future expires' do
    timeout_string = 'timeout'
    value = ConcurrentRails::Promises.future { sleep 0.2 }.
            value(0.1, timeout_string)

    assert_equal(value, timeout_string)
  end
end
