###

  PrismTech licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with the
  License and with the PrismTech Vortex product. You may obtain a copy of the
  License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  License and README for the specific language governing permissions and
  limitations under the License.

###


#
# coffez is a library that provides a few useful functional abstractions such as Option and Try types
#

root = {}
###*
Define the coffez library. It includes a few useful functional abstractions such as Option and Try types.
@namespace
###
root.coffez = {}


# `Option` monad implementation.
###*
@memberof coffez
@class
@classdesc this class, used with the CSome class defines the Option
(Maybe) Monad. This monad is used throughout the API to deal with
operations that may not return a valid result.
###
None = {}
###*
  returns None whatever the function to apply.
     @param {function} f - the function to apply
     @returns {None} - None object
     @memberof! coffez.None#
     @function map
###
None.map = (f) -> None

###*
  returns None whatever the function to apply.
     @param {function} f - the function to apply
     @returns {None} - None object
     @memberof! coffez.None#
     @function flatMap
###
None.flatMap = (f) -> None


###*
  returns the Option's value.
     @returns {undefined} - undefined type
     @memberof! coffez.None#
     @function get
###
None.get = () -> undefined


###*
  returns the Option's value if the option is non empty, otherwise return the result of evaluating `f`
     @param {function} f - the default value
     @returns {*} - `f` result
     @memberof! coffez.None#
     @function getOrElse
###
None.getOrElse = (f) -> f()


###*
  returns this Option if it is non empty, otherwise return the result of evaluating `f`.
     @param {function} f - the default value
     @returns {*} - the result of evaluating f
     @memberof! coffez.None#
     @function orElse
###
None.orElse = (f) -> f()


###*
  returns true if the Option is empty.
     @returns {boolean} - true
     @memberof! coffez.None#
     @function isEmpty
###
None.isEmpty = () -> true


###*
@memberof coffez
@class
@classdesc this class, used with the None class defines the Option
(Maybe) Monad. This monad is used throughout the API to deal with
operations that may not return a valid result.
###
class CSome
  constructor: (@value) ->

    ###*
    returns a Some containing the result of applying `f` to this Option value.
       @param {function} f - the function to apply
       @returns {CSome} - CSome object
       @memberof! coffez.CSome#
       @function map
    ###
  map: (f)  -> new CSome(f(@value))

  ###*
  returns the result of applying `f` to this Option value.
     @param {function} f - the function to apply
     @returns {*} - f result
     @memberof! coffez.CSome#
     @function flatMap
  ###
  flatMap: (f) -> f(@value)

  ###*
  returns the Option's value.
     @returns {*} - option's value
     @memberof! coffez.CSome#
     @function get
  ###
  get: () -> @value

  ###*
  returns the Option's value if the option is non empty, otherwise return the result of evaluating `f`
     @param {function} f - the default value
     @returns {*} - f result
     @memberof! coffez.CSome#
     @function getOrElse
  ###
  getOrElse: (f) -> @value

  ###*
  returns this Option if it is non empty, otherwise return the result of evaluating `f`.
     @param {function} f - the default value
     @returns {Some} - this Option
     @memberof! coffez.CSome#
     @function orElse
  ###
  orElse: (f) -> this

  ###*
  returns true if the Option is empty.
     @returns {boolean} - false
     @memberof! coffez.CSome#
     @function isEmpty
  ###
  isEmpty: () -> false


class CFail
  constructor: (@what) ->
  map: (f)  -> throw @what
  flatMap: (f) -> throw @what
  get: () -> throw @what
  getOrElse: (f) -> throw @what
  orElse: (f) -> throw @what
  isEmpty: () -> throw @what

# `Try` monad implementation.
class CSuccess
  constructor: (@value) ->
  map: (f) -> f(@value)
  get: () -> @value
  getOrElse: (f) -> @value
  orElse: (f) -> this
  isFailure: () -> false
  isSuccess: () -> true
  toOption: () -> new CSome(@value)
  recover: (f) -> this

class CFailure
  constructor: (@exception) ->
  map: (f) -> None
  get: () -> @exception
  getOrElse: (f) -> f()
  orElse: (f) -> f()
  isFailure: () -> true
  isSuccess: () -> false
  toOption: () -> None
  recover: (f) -> f(@exception)



ematch = (x, y) ->
  if (y == undefined) then true else x == y

omatch = (a, b) ->
  m = true
  for k,v of a
    e = match(v, b[k])
    m = m and e
  m

match = (a, b) ->
  switch typeof(a)
    when 'object'
      switch typeof(b)
        when 'object'
          omatch(a, b)
#if (Object.keys(a).length == Object.keys(b).length) then omatch(a, b) else false
        else
          false
    when 'function'
      false
    when 'undefined' then false
    else
      switch typeof(b)
        when 'object' then false
        when 'function' then false
        when 'undefined' then true
        else ematch(a, b)


root.coffez.None = None

###*
Utility function to create a `CSome` object
 @memberof coffez#
 @function Some
 @param {*} value - a given optional value
 @returns {CSome} - a `CSome` object
 @see coffez.CSome
###
root.coffez.Some = (value) -> new CSome(value)
root.coffez.Fail = (what) -> new CFail(what)
root.coffez.Success = (value) -> new CSuccess(value)
root.coffez.Failure = (ex) -> new CFailure(ex)
root.coffez.match = match

module.exports = root.coffez
