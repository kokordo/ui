//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Thu, May 03, 2012  1:06:33 PM
// Author: tomyeh

/**
 * The callback when [Scroller] tries to start the scrolling.
 * If it returns false, the scroller won't be activated (i.e., ignored).
 */
typedef bool ScrollerStart(ScrollerState state);
/** The callback that [Scroller] uses to indicate the user is scrolling.
 */
typedef void ScrollerMove(ScrollerState state);
/** The callback when [Scroller] ends the scrolling.
 */
typedef void ScrollerEnd(ScrollerState state);
/** The callback to snap the given position to, say, a grid line.
 */
typedef Offset ScrollerSnap(Offset position);

/** The scroller used to scroll an element by use of its style's
 * transform property.
 */
interface Scroller default _Scroller {
  /** Constructor.
   *
   * + [start] is the callback before starting scrolling.
   * If it returns false, the scrolling won't be activated.
   * + [dir]: the direction. If not specified, [Dir.BOTH] is assumed.
   */
  Scroller(Element owner, AsSize viewPortSize, AsSize contentSize,
    [Element handle, Dir direction, bool scrollbar, ScrollerSnap snap, 
      ScrollerStart start, ScrollerMove move, ScrollerEnd end]);
  // TODO: inertial, bounce
  
  /** Stop current scrolling.
   */
  void stop();
  
  /** Destroys the scroller.
   * It shall be called to clean up the scroller, if it is no longer used.
   */
  void destroy();
  
  /** Returns the direction that the scrolling is allowed.
   */
  Dir get direction();
  
  /** Returns the owner that associates to the scroller.
   */
  Element get owner();
  
  /** Returns the handle element that associates to the scroller, if any.
   */
  Element get handle();
  
  /** Return true if it is currently scrolling.
   */
  bool isScrolling();
  
  /** Return the current scroll position.
   */
  Offset get scrollPosition();
  
  /** Set the scroll position. The current scrolling motion, if any, will be stopped.
   */
  void set scrollPosition(Offset position);
  
  /** Set the scroll position. The current scrolling, if any, will be stopped.
   * + If [animate], scroll to the position continously. Otherwise the position
   * is updated instantly.
   */
  void scrollTo(Offset position, [bool animate]);
  
}

/**
 * The state in a scolling process, provided by [Scroller] in [ScrollerStart] and
 * [ScrollerMove] callback.
 */
interface ScrollerState default _ScrollerState {
  
  /** Returns the associated [Scroller].
   */
  Scroller get scroller();
  
  /** Returns the current scroll offset.
   */
  Offset get position();
  
  /** Returns the current scrolling velocity.
   */
  Offset get velocity();
  
  /** Returns the latest timestamp at which the scroll position is updated.
   */
  int get time();
  
  /** Returns the size of view port.
   */
  Size get viewPortSize();
  
  /** Returns the content size.
   */
  Size get contentSize();
  
  /** Tell scroller state to re-determine view port and content sizes.
   */
  void resize();
  
}

/**
 * The controller of a virtual scroll bar which appears when scrolling.
 */
interface ScrollbarControl default _ScrollbarControl {
  
  /** Initialization of scroll bar.
   */
  void init(bool vertical);
  
  /** Destory the scroll bar.
   */
  void destroy(bool vertical);
  
  /** Called when scrolling starts.
   */
  void start(bool vertical, ScrollerState state);
  
  /** Called at each scrolling iteraion.
   */
  void move(bool vertical, ScrollerState state);
  
  /** Called when scrolling stops.
   */
  void end(bool vertical, ScrollerState state);
  
}

class _ScrollerState implements ScrollerState {
  
  final Scroller scroller;
  final AsSize _fnViewPortSize, _fnContentSize;
  final Offset startPosition;
  bool _hor, _ver;
  Offset _pos, _ppos;
  int _time, _ptime;
  
  _ScrollerState(_Scroller scroller, this._fnViewPortSize, this._fnContentSize, this._time) : 
    this.scroller = scroller,
    startPosition = new DOMQuery(scroller.owner).offset * -1 {
    _pos = startPosition;
    Size cs = contentSize, vs = viewPortSize;
    _hor = scroller._hasHor && cs.width > vs.width;
    _ver = scroller._hasVer && cs.height > vs.height;
  }
  
  Offset get position() => _pos;
  
  void snapshot(Offset pos, int time) {
    if (_time == null || time > _time) {
      _ppos = _pos;
      _ptime = _time;
      _pos = pos * -1;
      _time = time;
    }
  }
  
  Offset get velocity() => _ppos == null || _pos == null || _time == null || _ptime == null ? 
      new Offset(0, 0) : ((_pos - _ppos) / (_time - _ptime));
  
  int get time() => _time;
  
  // size cache //
  Size _contentSizeCache, _viewPortSizeCache;
  Rectangle _dragRangeCache;
  
  Rectangle get dragRange() {
    if (_dragRangeCache == null) {
      Size vsize = viewPortSize,
          csize = contentSize;
      _dragRangeCache = new Rectangle(vsize.width - csize.width, vsize.height - csize.height, 0, 0);
    }
    return _dragRangeCache;
  }
  
  Size get viewPortSize() {
    if (_viewPortSizeCache == null)
      _viewPortSizeCache = _fnViewPortSize();
    return _viewPortSizeCache;
  }
  
  Size get contentSize() {
    if (_contentSizeCache == null)
      _contentSizeCache = _fnContentSize();
    return _contentSizeCache;
  }
  
  void resize() {
    _viewPortSizeCache = _contentSizeCache = null;
    _dragRangeCache = null;
  }
  
}

class _ScrollbarControl implements ScrollbarControl {
  
  final Scroller scroller;
  final Element owner;
  Element _hbar, _vbar;
  
  _ScrollbarControl(this.scroller, this.owner);
  
  /* bar inner size: 4px
   * bar border: 1px
   * bar margin: 2px
   */
  static final _mgs = 2, _bds = 1, _ins = 4;
  
  void init(bool vertical) {
    if (vertical) {
      _vbar = new Element.tag("div");
      _vbar.classes = ["v-scrollbar-ver"];
      _vbar.style.width = CSS.px(_ins); // do here to have better sync
      _vbar.style.display = "none";
      owner.parent.insertBefore(_vbar, owner.nextElementSibling);
    } else {
      _hbar = new Element.tag("div");
      _hbar.classes = ["v-scrollbar-hor"];
      _hbar.style.height = CSS.px(_ins); // do here to have better sync
      _hbar.style.display = "none";
      owner.parent.insertBefore(_hbar, owner.nextElementSibling);
    }
  }
  
  void destroy(bool vertical) {
    if (vertical) {
      _vbar.remove();
      _vbar == null;
    } else {
      _hbar.remove();
      _hbar == null;
    }
  }
  
  void start(bool vertical, ScrollerState state) {
    _updateBarSize(vertical, state);
    _updateBarPosition(vertical, state);
    final Element bar = vertical ? _vbar : _hbar;
    bar.style.display = "block"; // TODO: animation + leave hook to cancel
  }
  
  void move(bool vertical, ScrollerState state) {
    _updateBarPosition(vertical, state);
  }
  
  void end(bool vertical, ScrollerState state) {
    final Element bar = vertical ? _vbar : _hbar;
    bar.style.display = "none"; // TODO: animation + leave hook to skip
  }
  
  void _updateBarSize(bool ver, ScrollerState state) {
    final Size csize = state.contentSize;
    final Size vsize = state.viewPortSize;
    final num csize0 = ver ? csize.height : csize.width;
    final num vsize0 = ver ? vsize.height : vsize.width;
    final num s = ((vsize0 - _mgs * 2) * (csize0 > vsize0 ? vsize0 / csize0 : 1)).toInt() - _bds * 2;
    final num off = (ver ? vsize.width : vsize.height) - _mgs - _ins - _bds * 2;
    if (ver) {
      _vbar.style.height = CSS.px(s);
      _vbar.style.left = CSS.px(off);
    } else {
      _hbar.style.width = CSS.px(s);
      _hbar.style.top = CSS.px(off);
    }
  }
  
  void _updateBarPosition(bool ver, ScrollerState state) {
    final Size csize = state.contentSize;
    final Size vsize = state.viewPortSize;
    final num csize0 = ver ? csize.height : csize.width;
    final num vsize0 = ver ? vsize.height : vsize.width;
    final num pos = ver ? state.position.y : state.position.x;
    final num x = _mgs + (csize0 > vsize0 ? ((vsize0 - _mgs * 2) * pos / csize0) : 0);
    if (ver)
      _vbar.style.top = CSS.px(x);
    else
      _hbar.style.left = CSS.px(x);
  }
  
}

/**
 * A custom-scrolling handler.
 */
class _Scroller implements Scroller {
  final Element owner, handle;
  final Dir direction;
  final bool _hasHor, _hasVer;
  final bool scrollbar;
  final ScrollerStart _start;
  final ScrollerMove _move;
  final ScrollerEnd _end;
  final AsSize _fnContentSize, _fnViewPortSize;
  
  DragGesture _dg;
  _BoundedInertialMotion _bim;
  _ScrollToMotion _stm;
  _ScrollerState _state;
  ScrollbarControl _scrollbarCtrl;
  
  _Scroller(this.owner, this._fnViewPortSize, AsSize this._fnContentSize,
  [Element handle, Dir direction = Dir.BOTH, bool scrollbar = true, 
  ScrollerSnap snap, ScrollerStart start, ScrollerMove move, ScrollerEnd end]) :
  this.handle = handle, this.direction = direction, this.scrollbar = scrollbar,
  _hasHor = direction === Dir.HORIZONTAL || direction === Dir.BOTH,
  _hasVer = direction === Dir.VERTICAL || direction === Dir.BOTH,
  _start = start, _move = move, _end = end {
    
    _dg = new DragGesture(this.owner, handle: handle,
    start: (DragGestureState state) => onStart(state.time) ? owner : null, // TODO: stop _stm
    move: (DragGestureState state) { 
      onMove(state.transition - _state.startPosition, state.time);
      return true; // custom moving handling
    }, end: (DragGestureState state) {
      final Offset pos = new DOMQuery(owner).offset;
      final Rectangle range = _state.dragRange;
      // always go through this motion
      _bim = new _BoundedInertialMotion(owner, state.velocity, range, 
        _hor, _ver, onMove, onEnd, snap: snap);
    });
    
    // init scroll bar
    if (scrollbar) {
      _scrollbarCtrl = _scrollbarControl();
      if (_scrollbarCtrl != null)
        _applyScrollBarFunction0(_scrollbarCtrl.init);
    }
    
    //TODO: support desktop - if not in simulator, mousewheel/draggable scrollbar
  }
  
  // scrolling mechanism //
  bool onStart(int time, [bool noCallback = false]) {
    if (_bim != null)
      _bim.stop();
    _state = new _ScrollerState(this, _fnViewPortSize, _fnContentSize, time);
    if (scrollbar && _scrollbarCtrl != null)
      _applyScrollBarFunction1(_scrollbarCtrl.start, _state);
    if (noCallback || _start == null)
      return true;
    final bool res = _start(_state);
    return res == null || res;
  }
  
  void onMove(Offset position, int time, [bool noCallback = false]) {
    _state.snapshot(position, time);
    if (scrollbar && _scrollbarCtrl != null)
      _applyScrollBarFunction1(_scrollbarCtrl.move, _state);
    if (!noCallback && _move != null)
      _move(_state);
    _applyPosition(position);
  }
  
  void onEnd([bool noCallback = false]) {
    if (!noCallback && _end != null)
      _end(_state);
    if (scrollbar && _scrollbarCtrl != null)
      _applyScrollBarFunction1(_scrollbarCtrl.end, _state);
    _state = null;
    _bim = null;
  }
  
  void _applyPosition(Offset position) {
    if (_hor)
      owner.style.left = CSS.px(position.left);
    if (_ver)
      owner.style.top = CSS.px(position.top);
  }
  
  // scroll bar //
  ScrollbarControl _scrollbarControl() => new _ScrollbarControl(this, this.owner);
  
  void _applyScrollBarFunction0(Function f) {
    if (_hor)
      f(false);
    if (_ver)
      f(true);
  }
  
  void _applyScrollBarFunction1(Function f, ScrollerState state) {
    if (_hor)
      f(false, state);
    if (_ver)
      f(true, state);
  }
  
  bool get _hor() => _state != null ? _state._hor : _hasHor;
  bool get _ver() => _state != null ? _state._ver : _hasVer;
  
  // query //
  bool isScrolling() => _state != null;
  
  Offset get scrollPosition() => 
      _state != null ? _state.position : (new DOMQuery(owner).offset * -1);
  
  // control //
  void set scrollPosition(Offset position) => scrollTo(position, false);
  
  void scrollTo(Offset position, [bool animate = true]) {
    position = position * -1;
    stop();
    if (animate) {
      _stm = new _ScrollToMotion(this, scrollPosition, position);
    } else {
      int time = new Date.now().millisecondsSinceEpoch;
      onStart(time, noCallback: true); // TODO: interrupt drag?
      onMove(position, time, noCallback: true);
      onEnd(noCallback: true);
    }
  }
  
  void stop() {
    if (_bim != null) {
      _bim.stop();
      _bim = null;
    }
    if (_stm != null) {
      _stm.stop();
      _stm = null;
    }
    _state = null;
  }
  
  void destroy() {
    _state = null;
    if (scrollbar && _scrollbarCtrl != null)
      _applyScrollBarFunction0(_scrollbarCtrl.destroy);
    _dg.destroy();
  }
  
}

class _ScrollToMotion extends EasingMotion {
  
  final _Scroller _scroller;
  final Offset _initPos, _diffPos;
  
  _ScrollToMotion(_Scroller scroller, Offset initPos, Offset destPos) :
  _scroller = scroller, _initPos = initPos, _diffPos = destPos - initPos, super(null);
  
  void onStart(MotionState state) {
    // TODO: interrupt?
    _scroller.onStart(state.currentTime, noCallback: true);
  }
  
  void onEnd(MotionState state) {
    _scroller.onEnd(noCallback: true);
  }
  
  bool doAction_(num x, MotionState state) {
    _scroller.onMove(_initPos + _diffPos * x, state.currentTime, noCallback: true);
    return true;
  }
  
}

class _BoundedInertialMotion extends Motion {
  
  final bool _hor, _ver;
  final Element element;
  final num friction, bounce, snapSpeedThreshold;
  final Rectangle range;
  final Function _move, _end, _snap;
  Offset _pos, _vel;
  Motion _snapMotion;
  
  _BoundedInertialMotion(Element element, Offset velocity, this.range, 
  this._hor, this._ver, void move(Offset position, int time), void end(),
  [num friction = 0.0005, num bounce = 0.0002, num snapSpeedThreshold = 0.05, ScrollerSnap snap]) :
  this.element = element, this.friction = friction, this.bounce = bounce,
  this.snapSpeedThreshold = snapSpeedThreshold, _move = move, _end = end, _snap = snap,
  _pos = new DOMQuery(element).offset, _vel = velocity, super(null) {
    if (!_hor)
      _vel.x = 0;
    if (!_ver)
      _vel.y = 0;
  }
  
  bool onMove(MotionState state) {
    final num speed = _vel.norm();
    final Offset dir = speed == 0 ? new Offset(0, 0) : _vel / speed;
    final Offset dec = dir * friction;
    
    if (_hor)
      _pos.x = _updatePosition(_pos.x, _vel.x, dec.x, state.elapsedTime, range.x, range.right);
    if (_ver)
      _pos.y = _updatePosition(_pos.y, _vel.y, dec.y, state.elapsedTime, range.y, range.bottom);
    
    if (_move != null)
      _move(_pos, state.currentTime);
    
    if (_hor)
      _vel.x = _updateVelocity(_pos.x, _vel.x, dec.x, state.elapsedTime, range.x, range.right);
    if (_ver)
      _vel.y = _updateVelocity(_pos.y, _vel.y, dec.y, state.elapsedTime, range.y, range.bottom);
    
    if (_shallSnap())
      return false;
    
    return (_hor && !_shallStop(_pos.x, _vel.x, range.x, range.right)) ||
        (_ver && !_shallStop(_pos.y, _vel.y, range.y, range.bottom)); 
  }
  
  void onEnd(MotionState state) {
    if (_snapTo != null) {
      _snapMotion = new LinearPathMotion(element, _pos, _snapTo,
      move: (MotionState ms, Offset pos, num x) {
        if (_move != null)
          _move(pos, ms.currentTime);
      }, end: (MotionState ms) {
        if (_end != null)
          _end();
      }, duration: 200, easing: (num x) => x * x);
    } else if (_end != null)
      _end();
  }
  
  void stop() {
    if (_snapMotion != null)
      _snapMotion.stop();
    super.stop();
  }
  
  num _updatePosition(num pos, num vel, num dec, int elap, num lbnd, num rbnd) {
    num npos = pos + vel * elap;
    if (pos < lbnd && npos > lbnd && vel > 0)
      return lbnd;
    else if (pos > rbnd && npos < rbnd && vel < 0)
      return rbnd;
    return npos;
  }
  
  num _updateVelocity(num pos, num vel, num dec, int elap, num lbnd, num rbnd) {
    if ((pos == lbnd && vel > 0) || (pos == rbnd && vel < 0))
      return 0;
    num acc = pos < lbnd ? (lbnd - pos) * bounce :
              pos > rbnd ? (rbnd - pos) * bounce : -dec;
    num nvel = vel + acc * elap;
    if ((nvel > 0 && vel < 0) || (nvel < 0 && vel > 0)) // decelerate to 0 at most
      return 0;
    return nvel;
  }
  
  bool _shallStop(num pos, num vel, num lbnd, num rbnd) =>
    lbnd <= pos && pos <= rbnd && vel == 0;
  
  // snap //
  Offset _snapTo;
  
  bool _shallSnap() {
    // use max, not norm, as x/y motion should be considered independent
    // i.e. shall snap when both x & y motion are nearly stopped
    if (_snap == null || _vel.x.abs() > snapSpeedThreshold || _vel.y.abs() > snapSpeedThreshold)
      return false;
    // do not snap outside of the range
    if ((!_hor || _pos.x < range.x || _pos.x > range.right) &&
        (!_ver || _pos.y < range.y || _pos.y > range.bottom))
      return false;
    Offset scrPos = _pos * -1, scrSnapPos = _snap(scrPos);
    if (scrSnapPos == null)
      return false;
    scrSnapPos = range.snap(scrSnapPos * -1) * -1;
    if ((!_hor || scrSnapPos.x == scrPos.x) &&
        (!_ver || scrSnapPos.y == scrPos.y))
      return false;
    _snapTo = scrSnapPos * -1;
    return true;
  }
  
}
