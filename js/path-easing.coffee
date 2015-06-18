h = require './h'

# ## PathEasing
# Class allows you to specify custom easing function
# by **SVG path** [line commands](http://goo.gl/LzvV6P).
# Line commands should by in range of rect 100x100.
# @param {String, DOMNode}
# @param {Object} options  
#   - precision {Number} Presicion for the output,
#     defines amount of samples for the sample function. *default: 24*
#   - rect      {Number} The largest
#     number SVG path coordinates can have *default: 100*
class PathEasing
  constructor:(path, o={})->
    # the class can work as a "creator" of self instances
    # so no need to init if 'creator' passed insted of path
    return if path is 'creator'
    @path = h.parsePath(path)
    return h.error 'Error while parsing the path' if !@path?
    @pathLength = @path?.getTotalLength()
    @precision = o.precision or 24; @rect = o.rect or 100
    @sample = h.bind(@sample, @)
    @_eps = 0.0000000001
    # console.time 'pre sample'
    @_preSample()
    # console.timeEnd 'pre sample'
    @

  _preSample:->
    @_samples = {}

    stepsCount = 100; step = 1/stepsCount; progress = 0
    for i in [0..stepsCount]
      y = @path.getPointAtLength(@pathLength*progress).y
      # divide y by rect value and invert it
      @_samples[progress] = 1 - (y/@rect)
      progress += step
      # fix decimal fraction issue
      progress = parseFloat progress.toFixed(2)

  # ---

  # Loop thru path trying to find the most closer x
  # compared to current progress value
  # 
  # @method sample
  # @param  {Number} easing progress in range [0,1]
  # @return {Number} easing y
  sample:(p, start=0, end=1, precision=@precision)->
    p = h.clamp p, 0, 1
    # if there is sampled value, then use it
    sampled = @_samples[p]
    return sampled if sampled?
    # if there is no sampled value,
    # find the nearest start and end values
    #   nearest start:
    startKey = parseFloat(p.toFixed(2)); endKey = 1
    # if startKey compared to progress is about the same (_eps)
    # return the startKey right here
    keys = Object.keys(@_samples)
    # we called toFixed(2) to be sure that we have the sampled value
    # in _samples object but we need to check now, if startKey was rounded
    # to larger number, for instance .705 will coerce .71 and it is larger
    # then the progress itself so, decrease the startIndex value by 1 
    
    if startKey > p
      startObject = @_findSmaller(keys, startKey)
      startKey   = startObject.value
      startIndex = startObject.index
    else startIndex = keys.indexOf(startKey+'')
    return @_samples[startKey] if Math.abs(startKey - p) < @_eps

    endKey   = @_findLarger(keys, p, startIndex)
    # if endKey compared to progress is about the same (_eps)
    # return the startKey right here
    # return @_samples[endKey] if Math.abs(endKey - p) < @_eps


    # console.log startKey

    # return 'unresolved return'


    # console.log startKey, endKey
    # center = start+((end-start)/2)
    # point  = @path.getPointAtLength (@pathLength*center)

    # rect = @rect
    # # orient is point.x
    # if rect*p > point.x      then newStart = center; newEnd = end
    # else if rect*p < point.x then newStart = start; newEnd = center
    # else return 1 - point.y/rect
    
    # # if precise enough then return result
    # return if --precision < 1 then 1 - point.y/rect
    # # else sample further
    # else @sample p, newStart, newEnd, precision
  # ---

  # @method _findSmaller
  # @param  {Array}  array of keys
  # @param  {Number} value to start from
  # @param  {Number, Null} index to start from
  # @return {Object}
  #         - value: smaller key value
  #         - index: it's index in array
  _findSmaller:(array, value, startIndex)->
    # find the index of the value
    if !startIndex? then startIndex = array.indexOf(value+'')
    # return the smallest value possible if nothing was found
    return {value: 0, index: 0} if startIndex <= 0
    
    currentValue = array[startIndex-1]
    if currentValue < value
      return {value: parseFloat(currentValue), index: startIndex-1}
    else @_findSmaller array, value, startIndex-1
  # ---

  # @method _findLarger
  # @param  {Array}  array of keys
  # @param  {Number} value to start from
  # @param  {Number, Null} index to start from
  # @return {String} larger key
  _findLarger:(array, value, startIndex)->
    if !startIndex? then startIndex = array.indexOf(value+'')
    return 1 if startIndex >= array.length or startIndex <= 0
    currentValue = array[startIndex+1]
    if currentValue > value then return parseFloat(currentValue)
    else @_findLarger array, value, startIndex+1
  # ---

  # Create new instance of PathEasing with specified parameters
  # *Please see the docs for PathEasing for more details on params.*
  # 
  # @method create
  # @param  {String, DOMNode} path
  # @return {Object} easing y
  create:(path, o)-> (new PathEasing(path, o)).sample

module.exports = PathEasing
