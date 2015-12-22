define (require) ->
  'use strict'
  _ = require 'underscore'
  $ = require 'jquery'
  Raphael = require 'raphael'
  DisplayObject = require 'display_objects/display_object'
  Colors = require 'lib/colors'
  TypeData = require 'lib/type_data'

  # Shortcuts
  # ---------

  PI = Math.PI

  sin = Math.sin
  cos = Math.cos

  class IndicatorVisualization extends DisplayObject

    ANIMATION_DURATION = 1000

    # Property declarations
    # ---------------------
    #
    # circle: Raphael.Element
    # percentCircle: Raphael.Element
    # percentArc: Raphael.Element
    # percentOverlay: Raphael.Element
    #
    # Drawing variables which are passed in:
    #
    # paper: Raphael.Paper
    # x: Number
    # y: Number
    # width: Number
    # height: Number
    # data: Object

    DRAW_OPTIONS: 'paper x y width height data'.split(' ')

    draw: (options) ->
      @saveDrawOptions options

      func = switch @data.representation
        when TypeData.UNIT_ABSOLUTE then @drawCircle
        when TypeData.UNIT_PROPORTIONAL then @drawPercent
      func.apply this

      @addMouseHandlers()

      @drawn = true
      return

    # Draws the circle visualization (absolute)
    # -----------------------------------------

    drawCircle: ->
      {paper, x, y, width, height, data} = this

      x += width / 2
      y += height / 2
      max = width / 2
      min = max * 0.25
      radius = data.scale * (max - min) + min
      radius = min if radius < min
      fillColor = if data.value < 0 then Colors.red else Colors.lightGray

      if @circle
        @circle
          .stop()
          .animate({fill: fillColor, r: radius}, ANIMATION_DURATION, 'linear')
      else
        @circle = paper.circle(x, y, radius)
          .attr(fill: fillColor, 'stroke-opacity': 0)
        @addChild @circle

      return

    # Draws the percent visualization (proportional)
    # ----------------------------------------------

    drawPercent: ->
      {paper, x, y, width, height, data} = this

      x +=  width / 2
      y += height / 2
      radius = width / 2

      # Circle in background
      unless @percentCircle
        @percentCircle = paper.circle(x, y, radius)
          .attr(fill: Colors.lightGray, 'stroke-opacity': 0)
        @addChild @percentCircle

      # Percent arc
      ratio = data.value / 100
      fillColor = if ratio < 0 then Colors.red else '#2a5666'
      arcAttributes = fill: fillColor, 'stroke-opacity': 0
      # TODO test different ratios (<0, >1…)

      if Math.abs(ratio) >= 1
        if @arc
          arcAttributes.r = radius
          @percentArc
            .stop()
            .animate(arcAttributes, ANIMATION_DURATION, 'linear')
        else
          @percentArc = paper.circle(x, y, radius).attr(arcAttributes)
          @addChild @percentArc
      else
        degrees = 360 * ratio
        radians = (PI * 2 * ratio) - PI / 2
        pathString = """
          M {0}, {1}
          v {2}
          A {3}, {3} {4} {5} {6} {7}, {8}
          z
        """
        pathString = Raphael.format(pathString,
          x, y,
          0 - radius,
          radius,
          degrees,
          if Math.abs(degrees) >= 180 then 1 else 0,
          if ratio < 0 then 0 else 1,
          x + (radius * cos(radians)),
          y + (radius * sin(radians))
        )
        if @percentArc
          arcAttributes.path = pathString
          @percentArc
            .stop()
            .animate(arcAttributes, ANIMATION_DURATION, 'linear')
        else
          @percentArc = paper.path(pathString).attr(arcAttributes)
          @addChild @percentArc

      # Small white circle on top of all
      unless @percentOverlay
        @percentOverlay = paper.circle(x, y, radius * 0.55)
          .attr(fill: Colors.white, 'stroke-opacity': 0)
        @addChild @percentOverlay

      return

    # Mouse event handling
    # --------------------

    addMouseHandlers: ->
      for displayObject in @displayObjects
        node = displayObject.node
        $(node).hover(@mouseenterHandler, @mouseleaveHandler) if node

    mouseenterHandler: =>
      @trigger 'mouseenter', this

    mouseleaveHandler: =>
      @trigger 'mouseleave', this
