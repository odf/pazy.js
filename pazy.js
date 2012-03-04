(function() {
  var ArrayNode, BASE, BASE_LENGTH, BitmapIndexedNode, CheckedInt, Collection, CollisionNode, CountedExtensions, CountedSeq, DefaultExtensions, EmptyNode, FingerTreeType, Fraction, HALFBASE, HashLeaf, HashLeafWithValue, HashMap, HashSet, IntLeaf, IntLeafWithValue, IntMap, IntSet, LongInt, NumberBase, OrderMeasure, Partition, ProxyNode, Queue, Sequence, SizeMeasure, SortedExtensions, SortedSeqType, Stack, Void, a, asNum, b, bounce, c, cantor_fold, cantor_runs, combinator, equal, fromArray, hashCode, log, memo, method, num, quicktest, s, selfHashing, seq, show, skip, suspend, util, _base, _ref, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __slice = Array.prototype.slice,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (_base = Array.prototype).equals || (_base.equals = function(other) {
    var i, _ref;
    if (this.length !== other.length) {
      return false;
    } else {
      for (i = 0, _ref = this.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        if (!equal(this[i], other[i])) return false;
      }
      return true;
    }
  });

  equal = function(obj1, obj2) {
    if (typeof (obj1 != null ? obj1.equals : void 0) === 'function') {
      return obj1.equals(obj2);
    } else if (typeof (obj2 != null ? obj2.equals : void 0) === 'function') {
      return obj2.equals(obj1);
    } else {
      return obj1 === obj2;
    }
  };

  selfHashing = function(obj) {
    return typeof obj === "number" && ((0x100000000 > obj && obj >= 0)) && (obj % 1 === 0);
  };

  hashCode = function(obj) {
    var i, s, val, _ref;
    if (typeof (obj != null ? obj.hashCode : void 0) === 'function') {
      return obj.hashCode();
    } else if (selfHashing(obj)) {
      return obj;
    } else {
      s = "" + obj;
      val = 0;
      for (i = 0, _ref = s.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        val = (val * 37 + s.charCodeAt(i)) & 0xffffffff;
      }
      return val;
    }
  };

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref = this.pazy) != null ? _ref : this.pazy = {};
  }

  exports.equal = equal;

  exports.hashCode = hashCode;

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref2 = this.pazy) != null ? _ref2 : this.pazy = {};
  }

  exports.suspend = function(code) {
    var f;
    f = function() {
      var val;
      val = code();
      return (f = function() {
        return val;
      })();
    };
    return function() {
      return f();
    };
  };

  exports.bounce = function(val) {
    while (typeof val === 'function') {
      val = val();
    }
    return val;
  };

  exports.scope = function(args, f) {
    return f.apply(null, args);
  };

  if (typeof require !== 'undefined') {
    equal = require('core_extensions').equal;
    bounce = require('functional').bounce;
  } else {
    _ref3 = this.pazy, equal = _ref3.equal, bounce = _ref3.bounce;
  }

  Sequence = (function() {

    function Sequence(first, rest) {
      this.first = first;
      this.rest = rest;
    }

    return Sequence;

  })();

  skip = function(a, i) {
    if (i >= a.length || a[i] !== void 0) {
      return fromArray(a, i);
    } else {
      return function() {
        return skip(a, i + 1);
      };
    }
  };

  fromArray = function(a, i) {
    if (i >= a.length) {
      return null;
    } else if (a[i] === void 0) {
      return bounce(skip(a, i));
    } else {
      return seq.conj(a[i], function() {
        return fromArray(a, i + 1);
      });
    }
  };

  seq = function(src) {
    if (!(src != null)) {
      return null;
    } else if (src.constructor === Sequence) {
      return src;
    } else if (typeof src.toSeq === 'function') {
      return src.toSeq();
    } else if (typeof src.length === 'number') {
      return fromArray(src, 0);
    } else if (typeof src.first === 'function' && typeof src.rest === 'function') {
      return src;
    } else {
      throw new Error("cannot make a sequence from " + src);
    }
  };

  seq.conj = function(first, rest, mode) {
    var r;
    if (!(rest != null)) {
      return new Sequence((function() {
        return first;
      }), function() {
        return null;
      });
    } else if (mode === 'forced') {
      r = rest();
      return new Sequence((function() {
        return first;
      }), function() {
        return r;
      });
    } else {
      return new Sequence((function() {
        return first;
      }), function() {
        var val;
        val = rest();
        return (this.rest = function() {
          return val;
        })();
      });
    }
  };

  seq.from = function(start) {
    var _this = this;
    return seq.conj(start, function() {
      return seq.from(start + 1);
    });
  };

  seq.range = function(start, end) {
    return seq.take__(seq.from(start), end - start + 1);
  };

  seq.constant = function(value) {
    var _this = this;
    return seq.conj(value, function() {
      return seq.constant(value);
    });
  };

  seq.memo = memo = function(name, f) {
    seq[name] = function(s) {
      return f.call(seq, seq(s));
    };
    seq["" + name + "__"] = function(s) {
      return f.call(seq, s);
    };
    return Sequence.prototype[name] = function() {
      var x;
      x = f.call(seq, this);
      return (this[name] = function() {
        return x;
      })();
    };
  };

  seq.method = method = function(name, f) {
    seq[name] = function() {
      var args, s;
      s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return f.call.apply(f, [seq, seq(s)].concat(__slice.call(args)));
    };
    seq["" + name + "__"] = function() {
      var args, s;
      s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return f.call.apply(f, [seq, s].concat(__slice.call(args)));
    };
    return Sequence.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return f.call.apply(f, [seq, this].concat(__slice.call(args)));
    };
  };

  seq.combinator = combinator = function(name, f) {
    var namex;
    namex = "" + name + "__";
    seq[namex] = function(seqs) {
      return f.call(seq, seqs);
    };
    seq[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return seq[namex](seq.map(args, seq));
    };
    return Sequence.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return seq[name].apply(seq, [this].concat(__slice.call(args)));
    };
  };

  method('empty', function(s) {
    return !(s != null);
  });

  memo('size', function(s) {
    var step;
    step = function(t, n) {
      if (t) {
        return function() {
          return step(t.rest(), n + 1);
        };
      } else {
        return n;
      }
    };
    return bounce(step(s, 0));
  });

  memo('last', function(s) {
    var step;
    step = function(t) {
      if (t.rest()) {
        return function() {
          return step(t.rest());
        };
      } else {
        return t.first();
      }
    };
    if (s) return bounce(step(s));
  });

  method('take', function(s, n) {
    var _this = this;
    if (s && n > 0) {
      return this.conj(s.first(), function() {
        return _this.take__(s.rest(), n - 1);
      });
    } else {
      return null;
    }
  });

  method('takeWhile', function(s, pred) {
    var _this = this;
    if (s && pred(s.first())) {
      return this.conj(s.first(), function() {
        return _this.takeWhile__(s.rest(), pred);
      });
    } else {
      return null;
    }
  });

  method('drop', function(s, n) {
    var step;
    step = function(t, n) {
      if (t && n > 0) {
        return function() {
          return step(t.rest(), n - 1);
        };
      } else {
        return t;
      }
    };
    if (s) {
      return bounce(step(s, n));
    } else {
      return null;
    }
  });

  method('dropWhile', function(s, pred) {
    var step;
    step = function(t) {
      if (t && pred(t.first())) {
        return function() {
          return step(t.rest());
        };
      } else {
        return t;
      }
    };
    if (s) {
      return bounce(step(s));
    } else {
      return null;
    }
  });

  method('get', function(s, n) {
    var _ref4;
    if (n >= 0) {
      return (_ref4 = this.drop__(s, n)) != null ? _ref4.first() : void 0;
    }
  });

  method('select', function(s, pred) {
    var _this = this;
    if (s && pred(s.first())) {
      return this.conj(s.first(), function() {
        return _this.select__(s.rest(), pred);
      });
    } else if (s != null ? s.rest() : void 0) {
      return this.select__(this.dropWhile__(s.rest(), function(x) {
        return !pred(x);
      }), pred);
    } else {
      return null;
    }
  });

  method('find', function(s, pred) {
    var _ref4;
    return (_ref4 = this.select__(s, pred)) != null ? _ref4.first() : void 0;
  });

  method('forall', function(s, pred) {
    return !this.select__(s, function(x) {
      return !pred(x);
    });
  });

  method('map', function(s, func) {
    var _this = this;
    if (s) {
      return this.conj(func(s.first()), function() {
        return _this.map__(s.rest(), func);
      });
    } else {
      return null;
    }
  });

  method('accumulate', function(s, start, op) {
    var first,
      _this = this;
    if (s) {
      first = op(start, s.first());
      return this.conj(first, function() {
        return _this.accumulate__(s.rest(), first, op);
      });
    } else {
      return null;
    }
  });

  method('sums', function(s) {
    return this.accumulate__(s, 0, function(a, b) {
      return a + b;
    });
  });

  method('products', function(s) {
    return this.accumulate__(s, 1, function(a, b) {
      return a * b;
    });
  });

  method('reduce', function(s, start, op) {
    var step;
    step = function(t, val) {
      if (t) {
        return function() {
          return step(t.rest(), op(val, t.first()));
        };
      } else {
        return val;
      }
    };
    return bounce(step(s, start));
  });

  method('sum', function(s) {
    return this.reduce__(s, 0, function(a, b) {
      return a + b;
    });
  });

  method('product', function(s) {
    return this.reduce__(s, 1, function(a, b) {
      return a * b;
    });
  });

  method('fold', function(s, op) {
    return this.reduce__(s != null ? s.rest() : void 0, s != null ? s.first() : void 0, op);
  });

  method('max', function(s) {
    return this.fold__(s, function(a, b) {
      if (b > a) {
        return b;
      } else {
        return a;
      }
    });
  });

  method('min', function(s) {
    return this.fold__(s, function(a, b) {
      if (b < a) {
        return b;
      } else {
        return a;
      }
    });
  });

  combinator('zip', function(seqs) {
    var firsts;
    firsts = seqs != null ? seqs.map(function(s) {
      if (s != null) {
        return s.first();
      } else {
        return null;
      }
    }) : void 0;
    if (seq.find(firsts, function(x) {
      return x != null;
    }) != null) {
      return seq.conj(firsts, function() {
        return seq.zip__(seq.map(seqs, function(s) {
          return s != null ? s.rest() : void 0;
        }));
      });
    } else {
      return null;
    }
  });

  seq.combine = function() {
    var args, op, _ref4;
    op = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return (_ref4 = seq.zip.apply(seq, args)) != null ? _ref4.map(function(s) {
      return seq.fold(s, op);
    }) : void 0;
  };

  Sequence.prototype.combine = function() {
    var args, op;
    op = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return seq.combine.apply(seq, [op, this].concat(__slice.call(args)));
  };

  method('add', function() {
    var args, s;
    s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return seq.combine.apply(seq, [(function(a, b) {
      return a + b;
    }), s].concat(__slice.call(args)));
  });

  method('sub', function() {
    var args, s;
    s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return seq.combine.apply(seq, [(function(a, b) {
      return a - b;
    }), s].concat(__slice.call(args)));
  });

  method('mul', function() {
    var args, s;
    s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return seq.combine.apply(seq, [(function(a, b) {
      return a * b;
    }), s].concat(__slice.call(args)));
  });

  method('div', function() {
    var args, s;
    s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return seq.combine.apply(seq, [(function(a, b) {
      return a / b;
    }), s].concat(__slice.call(args)));
  });

  method('equals', function() {
    var args, s;
    s = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return this.forall__(seq.zip.apply(seq, [s].concat(__slice.call(args))), function(t) {
      var x;
      x = t != null ? t.first() : void 0;
      return seq.forall__(t != null ? t.rest() : void 0, function(y) {
        return equal(x, y);
      });
    });
  });

  method('lazyConcat', function(s, t) {
    var _this = this;
    if (s) {
      return this.conj(s.first(), function() {
        return _this.lazyConcat(s.rest(), t);
      });
    } else {
      return seq(t());
    }
  });

  combinator('concat', function(seqs) {
    var _this = this;
    if (seqs) {
      return this.lazyConcat(seqs.first(), function() {
        return _this.concat__(seqs.rest());
      });
    } else {
      return null;
    }
  });

  combinator('interleave', function(seqs) {
    var firsts, live,
      _this = this;
    live = seqs != null ? seqs.select(function(s) {
      return s != null;
    }) : void 0;
    if (live != null) {
      firsts = live.map(function(s) {
        return s.first();
      });
      return this.lazyConcat(firsts, function() {
        return _this.interleave__(live.map(function(s) {
          return s.rest();
        }));
      });
    } else {
      return null;
    }
  });

  method('flatten', function(s) {
    var _this = this;
    if (s && seq(s.first())) {
      return this.lazyConcat(seq(s.first()), function() {
        return _this.flatten__(s.rest());
      });
    } else if (s != null ? s.rest() : void 0) {
      return this.flatten__(this.dropWhile__(s.rest(), function(x) {
        return !seq(x);
      }));
    } else {
      return null;
    }
  });

  method('flatMap', function(s, func) {
    return this.flatten__(this.map__(s, func));
  });

  combinator('cartesian', function(seqs) {
    var _this = this;
    if (seqs) {
      if (seqs.rest()) {
        return this.flatMap__(seqs.first(), function(a) {
          var _ref4;
          return (_ref4 = _this.cartesian__(seqs.rest())) != null ? _ref4.map(function(s) {
            return _this.conj(a, function() {
              return s;
            });
          }) : void 0;
        });
      } else {
        return seqs.first().map(seq.conj);
      }
    } else {
      return null;
    }
  });

  cantor_fold = function(s, back, remaining) {
    var t, z;
    if (remaining) {
      t = seq.conj(remaining.first(), function() {
        return back;
      });
      z = s.zip(t).takeWhile(function(x) {
        return x != null ? x.get(1) : void 0;
      }).flatMap(function(x) {
        var a;
        a = x.first();
        return x.get(1).map(function(y) {
          return seq.conj(a, function() {
            return y;
          });
        });
      });
      return seq.conj(z, function() {
        return cantor_fold(s, t, remaining.rest());
      });
    } else {
      return null;
    }
  };

  cantor_runs = function(seqs) {
    if (seqs) {
      if (seqs.rest()) {
        return cantor_fold(seqs.first(), null, cantor_runs(seqs.rest()));
      } else {
        return seqs.first().map(function(x) {
          return seq.conj(seq.conj(x));
        });
      }
    } else {
      return null;
    }
  };

  combinator('cantor', function(seqs) {
    var _ref4;
    return (_ref4 = cantor_runs(seqs)) != null ? _ref4.flatten() : void 0;
  });

  method('subseqs', function(s) {
    var _this = this;
    if (s) {
      return this.conj(s, function() {
        return _this.subseqs__(s.rest());
      });
    } else {
      return null;
    }
  });

  method('each', function(s, func) {
    var step;
    step = function(t) {
      if (t) {
        func(t.first());
        return function() {
          return step(t.rest());
        };
      }
    };
    return bounce(step(s));
  });

  method('reverse', function(s) {
    var step,
      _this = this;
    step = function(r, t) {
      if (t) {
        return function() {
          return step(_this.conj(t.first(), function() {
            return r;
          }), t.rest());
        };
      } else {
        return r;
      }
    };
    return bounce(step(null, s));
  });

  method('forced', function(s) {
    var _this = this;
    if (s) {
      return this.conj(s.first(), (function() {
        return _this.forced__(s.rest());
      }), 'forced');
    } else {
      return null;
    }
  });

  method('into', function(s, target) {
    var a, x;
    if (!(target != null)) {
      return s;
    } else if (typeof target.plus === 'function') {
      return this.reduce__(s, target, function(t, item) {
        return t.plus(item);
      });
    } else if (typeof target.length === 'number') {
      a = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = target.length; _i < _len; _i++) {
          x = target[_i];
          _results.push(x);
        }
        return _results;
      })();
      this.each__(s, function(x) {
        return a.push(x);
      });
      return a;
    } else {
      throw new Error('cannot inject into #{target}');
    }
  });

  method('join', function(s, glue) {
    return this.into__(s, []).join(glue);
  });

  method('toString', function(s, limit) {
    var more, t, _ref4;
    if (limit == null) limit = 10;
    _ref4 = limit > 0 ? [this.take__(s, limit), this.get__(s, limit) != null] : [s, false], t = _ref4[0], more = _ref4[1];
    return '(' + this.join__(t, ', ') + (more ? ', ...)' : ')');
  });

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref4 = this.pazy) != null ? _ref4 : this.pazy = {};
  }

  exports.seq = seq;

  if ((typeof module !== "undefined" && module !== null) && !module.parent) {
    s = seq.from(1);
    console.log("" + (s.cantor(s, s).take(10)));
  }

  if (typeof require !== 'undefined') {
    _ref5 = require('core_extensions'), equal = _ref5.equal, hashCode = _ref5.hashCode;
    seq = require('sequence').seq;
  } else {
    _ref6 = this.pazy, equal = _ref6.equal, hashCode = _ref6.hashCode, seq = _ref6.seq;
  }

  util = {
    arrayWith: function(a, i, x) {
      var j, _ref7, _results;
      _results = [];
      for (j = 0, _ref7 = a.length; 0 <= _ref7 ? j < _ref7 : j > _ref7; 0 <= _ref7 ? j++ : j--) {
        _results.push(j === i ? x : a[j]);
      }
      return _results;
    },
    arrayWithInsertion: function(a, i, x) {
      var j, _ref7, _results;
      _results = [];
      for (j = 0, _ref7 = a.length; 0 <= _ref7 ? j <= _ref7 : j >= _ref7; 0 <= _ref7 ? j++ : j--) {
        _results.push(j < i ? a[j] : j > i ? a[j - 1] : x);
      }
      return _results;
    },
    arrayWithout: function(a, i) {
      var j, _ref7, _results;
      _results = [];
      for (j = 0, _ref7 = a.length; 0 <= _ref7 ? j < _ref7 : j > _ref7; 0 <= _ref7 ? j++ : j--) {
        if (j !== i) _results.push(a[j]);
      }
      return _results;
    },
    isKey: function(n) {
      return typeof n === "number" && ((0x100000000 > n && n >= 0)) && (n % 1 === 0);
    },
    mask: function(key, shift) {
      return (key >> (27 - shift)) & 0x1f;
    },
    bitCount: function(n) {
      n -= (n >> 1) & 0x55555555;
      n = (n & 0x33333333) + ((n >> 2) & 0x33333333);
      n = (n & 0x0f0f0f0f) + ((n >> 4) & 0x0f0f0f0f);
      n += n >> 8;
      return (n + (n >> 16)) & 0x3f;
    },
    indexForBit: function(bitmap, bit) {
      return util.bitCount(bitmap & (bit - 1));
    },
    bitPosAndIndex: function(bitmap, key, shift) {
      var bit;
      bit = 1 << util.mask(key, shift);
      return [bit, util.indexForBit(bitmap, bit)];
    }
  };

  EmptyNode = {
    size: 0,
    get: function(shift, key, data) {
      return;
    },
    elements: null,
    plus: function(shift, key, leaf) {
      return leaf;
    },
    minus: function(shift, key, data) {
      return this;
    },
    toString: function() {
      return "EmptyNode";
    }
  };

  BitmapIndexedNode = (function() {

    function BitmapIndexedNode(bitmap, progeny, size) {
      var _ref7;
      _ref7 = arguments.length === 0 ? [0, [], 0] : [bitmap, progeny, size], this.bitmap = _ref7[0], this.progeny = _ref7[1], this.size = _ref7[2];
      this.elements = seq.flatMap(this.progeny, function(n) {
        return n != null ? n.elements : void 0;
      });
    }

    BitmapIndexedNode.prototype.get = function(shift, key, data) {
      var bit, i, _ref7;
      _ref7 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref7[0], i = _ref7[1];
      if ((this.bitmap & bit) !== 0) {
        return this.progeny[i].get(shift + 5, key, data);
      }
    };

    BitmapIndexedNode.prototype.plus = function(shift, key, leaf) {
      var array, b, bit, i, m, n, newArray, node, progeny, v, _ref7;
      _ref7 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref7[0], i = _ref7[1];
      if ((this.bitmap & bit) === 0) {
        n = util.bitCount(this.bitmap);
        if (n < 8) {
          newArray = util.arrayWithInsertion(this.progeny, i, leaf);
          return new BitmapIndexedNode(this.bitmap | bit, newArray, this.size + 1);
        } else {
          progeny = (function() {
            var _results;
            _results = [];
            for (m = 0; m <= 31; m++) {
              b = 1 << m;
              if ((this.bitmap & b) !== 0) {
                _results.push(this.progeny[util.indexForBit(this.bitmap, b)]);
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          }).call(this);
          return new ArrayNode(progeny, util.mask(key, shift), leaf, this.size + 1);
        }
      } else {
        v = this.progeny[i];
        node = v.plus(shift + 5, key, leaf);
        if (this.bitmap === (1 << i)) {
          return new ProxyNode(i, node);
        } else {
          array = util.arrayWith(this.progeny, i, node);
          return new BitmapIndexedNode(this.bitmap, array, this.size + node.size - v.size);
        }
      }
    };

    BitmapIndexedNode.prototype.minus = function(shift, key, data) {
      var bit, bits, i, newArray, newBitmap, newSize, node, v, _ref7;
      _ref7 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref7[0], i = _ref7[1];
      v = this.progeny[i];
      node = v.minus(shift + 5, key, data);
      if (node != null) {
        newBitmap = this.bitmap;
        newSize = this.size + node.size - v.size;
        newArray = util.arrayWith(this.progeny, i, node);
      } else {
        newBitmap = this.bitmap ^ bit;
        newSize = this.size - 1;
        newArray = util.arrayWithout(this.progeny, i);
      }
      bits = util.bitCount(newBitmap);
      if (bits === 0) {
        return null;
      } else if (bits === 1) {
        node = newArray[0];
        if (node.progeny != null) {
          return new ProxyNode(util.bitCount(newBitmap - 1), node);
        } else {
          return node;
        }
      } else {
        return new BitmapIndexedNode(newBitmap, newArray, newSize);
      }
    };

    BitmapIndexedNode.prototype.toString = function(prefix) {
      var b, buf, m, pre;
      if (prefix == null) prefix = '';
      pre = prefix + ' ';
      buf = [];
      for (m = 0; m <= 31; m++) {
        b = 1 << m;
        if ((this.bitmap & b) !== 0) {
          buf.push(this.progeny[util.indexForBit(this.bitmap, b)].toString(pre));
        }
      }
      if (buf.length === 1) {
        return '{' + buf[0] + '}';
      } else {
        buf.unshift('');
        return '{' + buf.join('\n' + pre) + '}';
      }
    };

    return BitmapIndexedNode;

  })();

  ProxyNode = (function() {

    function ProxyNode(child_index, progeny) {
      this.child_index = child_index;
      this.progeny = progeny;
      this.size = this.progeny.size;
      this.elements = this.progeny.elements;
    }

    ProxyNode.prototype.get = function(shift, key, data) {
      if (this.child_index === util.mask(key, shift)) {
        return this.progeny.get(shift + 5, key, data);
      }
    };

    ProxyNode.prototype.plus = function(shift, key, leaf) {
      var array, bitmap, i;
      i = util.mask(key, shift);
      if (this.child_index === i) {
        return new ProxyNode(i, this.progeny.plus(shift + 5, key, leaf));
      } else {
        bitmap = (1 << this.child_index) | (1 << i);
        array = i < this.child_index ? [leaf, this.progeny] : [this.progeny, leaf];
        return new BitmapIndexedNode(bitmap, array, this.size + leaf.size);
      }
    };

    ProxyNode.prototype.minus = function(shift, key, data) {
      var node;
      node = this.progeny.minus(shift + 5, key, data);
      if ((node != null ? node.progeny : void 0) != null) {
        return new ProxyNode(this.child_index, node);
      } else {
        return node;
      }
    };

    ProxyNode.prototype.toString = function(prefix) {
      if (prefix == null) prefix = '';
      return '.' + this.progeny.toString(prefix + ' ');
    };

    return ProxyNode;

  })();

  ArrayNode = (function() {

    function ArrayNode(progeny, i, node, size) {
      this.size = size;
      this.progeny = util.arrayWith(progeny, i, node);
      this.elements = seq.flatMap(this.progeny, function(n) {
        return n != null ? n.elements : void 0;
      });
    }

    ArrayNode.prototype.get = function(shift, key, data) {
      var i;
      i = util.mask(key, shift);
      if (this.progeny[i] != null) {
        return this.progeny[i].get(shift + 5, key, data);
      }
    };

    ArrayNode.prototype.plus = function(shift, key, leaf) {
      var i, newSize, node;
      i = util.mask(key, shift);
      if (this.progeny[i] != null) {
        node = this.progeny[i].plus(shift + 5, key, leaf);
        newSize = this.size + node.size - this.progeny[i].size;
        return new ArrayNode(this.progeny, i, node, newSize);
      } else {
        return new ArrayNode(this.progeny, i, leaf, this.size + 1);
      }
    };

    ArrayNode.prototype.minus = function(shift, key, data) {
      var array, bitmap, i, j, node, remaining;
      i = util.mask(key, shift);
      node = this.progeny[i].minus(shift + 5, key, data);
      if (node != null) {
        return new ArrayNode(this.progeny, i, node, this.size - 1);
      } else {
        remaining = (function() {
          var _ref7, _results;
          _results = [];
          for (j = 0, _ref7 = this.progeny.length; 0 <= _ref7 ? j < _ref7 : j > _ref7; 0 <= _ref7 ? j++ : j--) {
            if (j !== i && this.progeny[j]) _results.push(j);
          }
          return _results;
        }).call(this);
        if (remaining.length <= 4) {
          bitmap = seq.reduce(remaining, 0, function(b, j) {
            return b | (1 << j);
          });
          array = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = remaining.length; _i < _len; _i++) {
              j = remaining[_i];
              _results.push(this.progeny[j]);
            }
            return _results;
          }).call(this);
          return new BitmapIndexedNode(bitmap, array, this.size - 1);
        } else {
          return new ArrayNode(this.progeny, i, null, this.size - 1);
        }
      }
    };

    ArrayNode.prototype.toString = function(prefix) {
      var buf, pre, x;
      if (prefix == null) prefix = '';
      pre = prefix + ' ';
      buf = (function() {
        var _i, _len, _ref7, _results;
        _ref7 = this.progeny;
        _results = [];
        for (_i = 0, _len = _ref7.length; _i < _len; _i++) {
          x = _ref7[_i];
          if (x != null) _results.push(x.toString(pre));
        }
        return _results;
      }).call(this);
      if (buf.length === 1) {
        return '[' + buf[0] + ']';
      } else {
        buf.unshift('');
        return '[' + buf.join('\n' + pre) + ']';
      }
    };

    return ArrayNode;

  })();

  Collection = (function() {

    function Collection(root) {
      var _ref7;
      this.root = root;
      if (this.root == null) this.root = EmptyNode;
      this.entries = (_ref7 = this.root) != null ? _ref7.elements : void 0;
    }

    Collection.prototype.size = function() {
      return this.root.size;
    };

    Collection.prototype.each = function(func) {
      var _ref7;
      if (func != null) {
        return (_ref7 = this.entries) != null ? _ref7.each(func) : void 0;
      } else {
        return this;
      }
    };

    Collection.prototype.update_ = function(root) {
      if (root !== this.root) {
        return new this.constructor(root);
      } else {
        return this;
      }
    };

    Collection.prototype.plus = function() {
      return this.plusAll(arguments);
    };

    Collection.prototype.plusAll = function(s) {
      return this.update_(seq.reduce(s, this.root, this.constructor.plusOne));
    };

    Collection.prototype.minus = function() {
      return this.minusAll(arguments);
    };

    Collection.prototype.minusAll = function(s) {
      return this.update_(seq.reduce(s, this.root, this.constructor.minusOne));
    };

    Collection.prototype.map = function(fun) {
      return new this.constructor().plusAll(seq.map(this.entries, fun));
    };

    Collection.prototype.toSeq = function() {
      return this.entries;
    };

    Collection.prototype.toArray = function() {
      return seq.into(this.entries, []);
    };

    Collection.prototype.toString = function() {
      return "" + this.constructor.name + "(" + this.root + ")";
    };

    return Collection;

  })();

  IntLeaf = (function() {

    function IntLeaf(key) {
      this.key = key;
      this.elements = seq.conj(this.key);
    }

    IntLeaf.prototype.size = 1;

    IntLeaf.prototype.get = function(shift, key, data) {
      return key === this.key;
    };

    IntLeaf.prototype.plus = function(shift, key, leaf) {
      return new BitmapIndexedNode().plus(shift, this.key, this).plus(shift, key, leaf);
    };

    IntLeaf.prototype.minus = function(shift, key, data) {
      return null;
    };

    IntLeaf.prototype.toString = function() {
      return "" + this.key;
    };

    return IntLeaf;

  })();

  IntSet = (function(_super) {

    __extends(IntSet, _super);

    function IntSet() {
      IntSet.__super__.constructor.apply(this, arguments);
    }

    IntSet.name = "IntSet";

    IntSet.prototype.contains = function(key) {
      return this.root.get(0, key) === true;
    };

    IntSet.plusOne = function(root, key) {
      if (util.isKey(key) && !root.get(0, key)) {
        return root.plus(0, key, new IntLeaf(key));
      } else {
        return root;
      }
    };

    IntSet.minusOne = function(root, key) {
      if (util.isKey(key) && (root != null ? root.get(0, key) : void 0)) {
        return root.minus(0, key);
      } else {
        return root;
      }
    };

    return IntSet;

  })(Collection);

  IntLeafWithValue = (function() {

    function IntLeafWithValue(key, value) {
      this.key = key;
      this.value = value;
      this.elements = seq.conj([this.key, this.value]);
    }

    IntLeafWithValue.prototype.size = 1;

    IntLeafWithValue.prototype.get = function(shift, key, data) {
      if (key === this.key) return this.value;
    };

    IntLeafWithValue.prototype.plus = function(shift, key, leaf) {
      if (this.key === key) {
        return leaf;
      } else {
        return new BitmapIndexedNode().plus(shift, this.key, this).plus(shift, key, leaf);
      }
    };

    IntLeafWithValue.prototype.minus = function(shift, key, data) {
      return null;
    };

    IntLeafWithValue.prototype.toString = function() {
      return "" + this.key + " ~> " + this.value;
    };

    return IntLeafWithValue;

  })();

  IntMap = (function(_super) {

    __extends(IntMap, _super);

    function IntMap() {
      IntMap.__super__.constructor.apply(this, arguments);
    }

    IntMap.name = "IntMap";

    IntMap.prototype.get = function(key) {
      return this.root.get(0, key);
    };

    IntMap.plusOne = function(root, _arg) {
      var key, value;
      key = _arg[0], value = _arg[1];
      if (util.isKey(key) && root.get(0, key) !== value) {
        return root.plus(0, key, new IntLeafWithValue(key, value));
      } else {
        return root;
      }
    };

    IntMap.minusOne = function(root, key) {
      if (util.isKey(key) && typeof (root != null ? root.get(0, key) : void 0) !== 'undefined') {
        return root.minus(0, key);
      } else {
        return root;
      }
    };

    return IntMap;

  })(Collection);

  CollisionNode = (function() {

    function CollisionNode(hash, bucket) {
      this.hash = hash;
      this.bucket = bucket;
      if (this.bucket == null) this.bucket = [];
      this.size = this.bucket.length;
      this.elements = seq.flatMap(this.bucket, function(n) {
        return n != null ? n.elements : void 0;
      });
    }

    CollisionNode.prototype.get = function(shift, hash, key) {
      var leaf;
      leaf = seq.find(this.bucket, function(v) {
        return equal(v.key, key);
      });
      if (leaf != null) return leaf.get(shift, hash, key);
    };

    CollisionNode.prototype.plus = function(shift, hash, leaf) {
      var newBucket;
      if (hash !== this.hash) {
        return new BitmapIndexedNode().plus(shift, this.hash, this).plus(shift, hash, leaf);
      } else {
        newBucket = this.bucketWithout(leaf.key);
        newBucket.push(leaf);
        return new CollisionNode(hash, newBucket);
      }
    };

    CollisionNode.prototype.minus = function(shift, hash, key) {
      switch (this.bucket.length) {
        case 0:
        case 1:
          return null;
        case 2:
          return seq.find(this.bucket, function(v) {
            return !equal(v.key, key);
          });
        default:
          return new CollisionNode(hash, this.bucketWithout(key));
      }
    };

    CollisionNode.prototype.toString = function() {
      return "" + (this.bucket.join("|"));
    };

    CollisionNode.prototype.bucketWithout = function(key) {
      var item, _i, _len, _ref7, _results;
      _ref7 = this.bucket;
      _results = [];
      for (_i = 0, _len = _ref7.length; _i < _len; _i++) {
        item = _ref7[_i];
        if (!equal(item.key, key)) _results.push(item);
      }
      return _results;
    };

    return CollisionNode;

  })();

  HashLeaf = (function() {

    function HashLeaf(hash, key) {
      this.hash = hash;
      this.key = key;
      this.elements = seq.conj(this.key);
    }

    HashLeaf.prototype.size = 1;

    HashLeaf.prototype.get = function(shift, hash, key) {
      if (equal(key, this.key)) return true;
    };

    HashLeaf.prototype.plus = function(shift, hash, leaf) {
      var base;
      if (hash === this.hash) {
        base = new CollisionNode(hash);
      } else {
        base = new BitmapIndexedNode();
      }
      return base.plus(shift, this.hash, this).plus(shift, hash, leaf);
    };

    HashLeaf.prototype.minus = function(shift, hash, key) {
      return null;
    };

    HashLeaf.prototype.toString = function() {
      return "" + this.key;
    };

    return HashLeaf;

  })();

  HashSet = (function(_super) {

    __extends(HashSet, _super);

    function HashSet() {
      HashSet.__super__.constructor.apply(this, arguments);
    }

    HashSet.name = "HashSet";

    HashSet.prototype.contains = function(key) {
      return this.root.get(0, hashCode(key), key) === true;
    };

    HashSet.plusOne = function(root, key) {
      var hash;
      hash = hashCode(key);
      if (root.get(0, hash, key)) {
        return root;
      } else {
        return root.plus(0, hash, new HashLeaf(hash, key));
      }
    };

    HashSet.minusOne = function(root, key) {
      var hash;
      hash = hashCode(key);
      if (root != null ? root.get(0, hash, key) : void 0) {
        return root.minus(0, hash, key);
      } else {
        return root;
      }
    };

    return HashSet;

  })(Collection);

  HashLeafWithValue = (function() {

    function HashLeafWithValue(hash, key, value) {
      this.hash = hash;
      this.key = key;
      this.value = value;
      this.elements = seq.conj([this.key, this.value]);
    }

    HashLeafWithValue.prototype.size = 1;

    HashLeafWithValue.prototype.get = function(shift, hash, key) {
      if (equal(key, this.key)) return this.value;
    };

    HashLeafWithValue.prototype.plus = function(shift, hash, leaf) {
      var base;
      if (equal(this.key, leaf.key)) {
        return leaf;
      } else {
        if (hash === this.hash) {
          base = new CollisionNode(hash);
        } else {
          base = new BitmapIndexedNode();
        }
        return base.plus(shift, this.hash, this).plus(shift, hash, leaf);
      }
    };

    HashLeafWithValue.prototype.minus = function(shift, hash, key) {
      return null;
    };

    HashLeafWithValue.prototype.toString = function() {
      return "" + this.key + " ~> " + this.value;
    };

    return HashLeafWithValue;

  })();

  HashMap = (function(_super) {

    __extends(HashMap, _super);

    function HashMap() {
      HashMap.__super__.constructor.apply(this, arguments);
    }

    HashMap.name = "HashMap";

    HashMap.prototype.get = function(key) {
      return this.root.get(0, hashCode(key), key);
    };

    HashMap.plusOne = function(root, _arg) {
      var hash, key, value;
      key = _arg[0], value = _arg[1];
      hash = hashCode(key);
      if (root.get(0, hash, key) === value) {
        return root;
      } else {
        return root.plus(0, hash, new HashLeafWithValue(hash, key, value));
      }
    };

    HashMap.minusOne = function(root, key) {
      var hash;
      hash = hashCode(key);
      if (typeof (root != null ? root.get(0, hash, key) : void 0) !== 'undefined') {
        return root.minus(0, hash, key);
      } else {
        return root;
      }
    };

    return HashMap;

  })(Collection);

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref7 = this.pazy) != null ? _ref7 : this.pazy = {};
  }

  exports.IntSet = IntSet;

  exports.IntMap = IntMap;

  exports.HashMap = HashMap;

  exports.HashSet = HashSet;

  if (typeof require !== 'undefined') {
    seq = require('sequence').seq;
    HashSet = require('indexed').HashSet;
  } else {
    _ref8 = this.pazy, seq = _ref8.seq, HashSet = _ref8.HashSet;
  }

  seq.method('uniq', function(s, seen) {
    var x,
      _this = this;
    if (seen == null) seen = new HashSet();
    if (s) {
      x = s.first();
      if (seen.contains(x)) {
        return this.uniq__(s.rest(), seen);
      } else {
        return seq.conj(x, function() {
          return _this.uniq__(s.rest(), seen.plus(x));
        });
      }
    } else {
      return null;
    }
  });

  if (typeof require !== 'undefined') {
    seq = require('sequence').seq;
    _ref9 = require('functional'), bounce = _ref9.bounce, suspend = _ref9.suspend;
  } else {
    seq = pazy.seq, bounce = pazy.bounce, suspend = pazy.suspend;
  }

  Void = (function() {

    function Void() {}

    return Void;

  })();

  DefaultExtensions = (function() {

    function DefaultExtensions() {}

    DefaultExtensions.prototype.after = function(x) {
      if (x === void 0) {
        return this;
      } else {
        return new this.constructor(this.data.after(x));
      }
    };

    DefaultExtensions.prototype.before = function(x) {
      if (x === void 0) {
        return this;
      } else {
        return new this.constructor(this.data.before(x));
      }
    };

    DefaultExtensions.prototype.concat = function(t) {
      if (!(t != null)) {
        return this;
      } else {
        return new this.constructor(this.data.concat(t.data));
      }
    };

    DefaultExtensions.prototype.reverse = function() {
      return new this.constructor(this.data.reverse());
    };

    DefaultExtensions.prototype.plus = DefaultExtensions.prototype.before;

    return DefaultExtensions;

  })();

  FingerTreeType = (function() {

    function FingerTreeType(measure, extensions) {
      var Deep, Digit1, Digit2, Digit3, Digit4, Empty, Instance, Node2, Node3, Single, empty, internal, norm, rev, single;
      if (extensions == null) extensions = DefaultExtensions;
      this.build = function() {
        return seq.reduce(arguments, empty, function(s, a) {
          return s.plus(a);
        });
      };
      single = function(x) {
        var _ref10;
        if (x === Empty || (_ref10 = x.constructor, __indexOf.call(internal, _ref10) >= 0)) {
          return x.measure();
        } else {
          return measure.single(x);
        }
      };
      norm = function() {
        return seq.reduce(arguments, measure.empty, function(n, x) {
          if (x != null) {
            return measure.sum(n, single(x));
          } else {
            return n;
          }
        });
      };
      rev = function(x) {
        var _ref10;
        if ((_ref10 = x != null ? x.constructor : void 0) === Node2 || _ref10 === Node3) {
          return x.reverse();
        } else {
          return x;
        }
      };
      Instance = (function(_super) {

        __extends(Instance, _super);

        function Instance(data) {
          this.data = data;
        }

        Instance.prototype.empty = function() {
          return empty;
        };

        Instance.prototype.isEmpty = function() {
          return this.data.isEmpty();
        };

        Instance.prototype.reduceLeft = function(z, op) {
          return this.data.reduceLeft(z, op);
        };

        Instance.prototype.reduceRight = function(op, z) {
          return this.data.reduceRight(op, z);
        };

        Instance.prototype.first = function() {
          return this.data.first();
        };

        Instance.prototype.last = function() {
          return this.data.last();
        };

        Instance.prototype.rest = function() {
          return new Instance(this.data.rest());
        };

        Instance.prototype.init = function() {
          return new Instance(this.data.init());
        };

        Instance.prototype.measure = function() {
          return this.data.measure();
        };

        Instance.prototype.split = function(p) {
          var l, r, x, _ref10;
          if (this.data !== Empty && p(norm(this.data))) {
            _ref10 = this.data.split(p, measure.empty), l = _ref10[0], x = _ref10[1], r = _ref10[2];
            return [new Instance(l), x, new Instance(r)];
          } else {
            return [this, void 0, new Instance(Empty)];
          }
        };

        Instance.prototype.takeUntil = function(p) {
          return this.split(p)[0];
        };

        Instance.prototype.dropUntil = function(p) {
          var l, r, x, _ref10;
          _ref10 = this.split(p), l = _ref10[0], x = _ref10[1], r = _ref10[2];
          if (x === void 0) {
            return r;
          } else {
            return new Instance(r.data.after(x));
          }
        };

        Instance.prototype.find = function(p) {
          return this.split(p)[1];
        };

        Instance.prototype.toSeq = function() {
          return this.data.reduceRight((function(x, s) {
            return seq.conj(x, function() {
              return s;
            });
          }), null);
        };

        Instance.prototype.toString = function() {
          return this.data.reduceLeft("", function(s, x) {
            return s + ' ' + x;
          });
        };

        return Instance;

      })(extensions);
      Node2 = (function() {

        function Node2(a, b) {
          this.a = a;
          this.b = b;
          this.v = norm(this.a, this.b);
        }

        Node2.prototype.reduceLeft = function(z, op) {
          return op(op(z, this.a), this.b);
        };

        Node2.prototype.reduceRight = function(op, z) {
          return op(this.a, op(this.b, z));
        };

        Node2.prototype.asDigit = function() {
          return new Digit2(this.a, this.b);
        };

        Node2.prototype.measure = function() {
          return this.v;
        };

        Node2.prototype.reverse = function() {
          return new Node2(rev(this.b), rev(this.a));
        };

        return Node2;

      })();
      Node3 = (function() {

        function Node3(a, b, c) {
          this.a = a;
          this.b = b;
          this.c = c;
          this.v = norm(this.a, this.b, this.c);
        }

        Node3.prototype.reduceLeft = function(z, op) {
          return op(op(op(z, this.a), this.b), this.c);
        };

        Node3.prototype.reduceRight = function(op, z) {
          return op(this.a, op(this.b, op(this.c, z)));
        };

        Node3.prototype.asDigit = function() {
          return new Digit3(this.a, this.b, this.c);
        };

        Node3.prototype.measure = function() {
          return this.v;
        };

        Node3.prototype.reverse = function() {
          return new Node3(rev(this.c), rev(this.b), rev(this.a));
        };

        return Node3;

      })();
      Digit1 = (function() {

        function Digit1(a) {
          this.a = a;
        }

        Digit1.prototype.reduceLeft = function(z, op) {
          return op(z, this.a);
        };

        Digit1.prototype.reduceRight = function(op, z) {
          return op(this.a, z);
        };

        Digit1.prototype.after = function(x) {
          return new Digit2(x, this.a);
        };

        Digit1.prototype.before = function(x) {
          return new Digit2(this.a, x);
        };

        Digit1.prototype.first = function() {
          return this.a;
        };

        Digit1.prototype.last = function() {
          return this.a;
        };

        Digit1.prototype.rest = function() {
          return Empty;
        };

        Digit1.prototype.init = function() {
          return Empty;
        };

        Digit1.prototype.measure = function() {
          return norm(this.a);
        };

        Digit1.prototype.split = function(p, i) {
          return [Empty, this.a, Empty];
        };

        Digit1.prototype.reverse = function() {
          return new Digit1(rev(this.a));
        };

        return Digit1;

      })();
      Digit2 = (function() {

        function Digit2(a, b) {
          this.a = a;
          this.b = b;
        }

        Digit2.prototype.reduceLeft = function(z, op) {
          return op(op(z, this.a), this.b);
        };

        Digit2.prototype.reduceRight = function(op, z) {
          return op(this.a, op(this.b, z));
        };

        Digit2.prototype.after = function(x) {
          return new Digit3(x, this.a, this.b);
        };

        Digit2.prototype.before = function(x) {
          return new Digit3(this.a, this.b, x);
        };

        Digit2.prototype.first = function() {
          return this.a;
        };

        Digit2.prototype.last = function() {
          return this.b;
        };

        Digit2.prototype.rest = function() {
          return new Digit1(this.b);
        };

        Digit2.prototype.init = function() {
          return new Digit1(this.a);
        };

        Digit2.prototype.asNode = function() {
          return new Node2(this.a, this.b);
        };

        Digit2.prototype.measure = function() {
          return norm(this.a, this.b);
        };

        Digit2.prototype.split = function(p, i) {
          if (p(measure.sum(i, norm(this.a)))) {
            return [Empty, this.a, new Digit1(this.b)];
          } else {
            return [new Digit1(this.a), this.b, Empty];
          }
        };

        Digit2.prototype.reverse = function() {
          return new Digit2(rev(this.b), rev(this.a));
        };

        return Digit2;

      })();
      Digit3 = (function() {

        function Digit3(a, b, c) {
          this.a = a;
          this.b = b;
          this.c = c;
        }

        Digit3.prototype.reduceLeft = function(z, op) {
          return op(op(op(z, this.a), this.b), this.c);
        };

        Digit3.prototype.reduceRight = function(op, z) {
          return op(this.a, op(this.b, op(this.c, z)));
        };

        Digit3.prototype.after = function(x) {
          return new Digit4(x, this.a, this.b, this.c);
        };

        Digit3.prototype.before = function(x) {
          return new Digit4(this.a, this.b, this.c, x);
        };

        Digit3.prototype.first = function() {
          return this.a;
        };

        Digit3.prototype.last = function() {
          return this.c;
        };

        Digit3.prototype.rest = function() {
          return new Digit2(this.b, this.c);
        };

        Digit3.prototype.init = function() {
          return new Digit2(this.a, this.b);
        };

        Digit3.prototype.asNode = function() {
          return new Node3(this.a, this.b, this.c);
        };

        Digit3.prototype.measure = function() {
          return norm(this.a, this.b, this.c);
        };

        Digit3.prototype.split = function(p, i) {
          var i1;
          i1 = measure.sum(i, norm(this.a));
          if (p(i1)) {
            return [Empty, this.a, new Digit2(this.b, this.c)];
          } else if (p(measure.sum(i1, norm(this.b)))) {
            return [new Digit1(this.a), this.b, new Digit1(this.c)];
          } else {
            return [new Digit2(this.a, this.b), this.c, Empty];
          }
        };

        Digit3.prototype.reverse = function() {
          return new Digit3(rev(this.c), rev(this.b), rev(this.a));
        };

        return Digit3;

      })();
      Digit4 = (function() {

        function Digit4(a, b, c, d) {
          this.a = a;
          this.b = b;
          this.c = c;
          this.d = d;
        }

        Digit4.prototype.reduceLeft = function(z, op) {
          return op(op(op(op(z, this.a), this.b), this.c), this.d);
        };

        Digit4.prototype.reduceRight = function(op, z) {
          return op(this.a, op(this.b, op(this.c, op(this.d, z))));
        };

        Digit4.prototype.first = function() {
          return this.a;
        };

        Digit4.prototype.last = function() {
          return this.d;
        };

        Digit4.prototype.rest = function() {
          return new Digit3(this.b, this.c, this.d);
        };

        Digit4.prototype.init = function() {
          return new Digit3(this.a, this.b, this.c);
        };

        Digit4.prototype.measure = function() {
          return norm(this.a, this.b, this.c, this.d);
        };

        Digit4.prototype.split = function(p, i) {
          var i1, i2;
          i1 = measure.sum(i, norm(this.a));
          if (p(i1)) {
            return [Empty, this.a, new Digit3(this.b, this.c, this.d)];
          } else {
            i2 = measure.sum(i1, norm(this.b));
            if (p(i2)) {
              return [new Digit1(this.a), this.b, new Digit2(this.c, this.d)];
            } else if (p(measure.sum(i2, norm(this.c)))) {
              return [new Digit2(this.a, this.b), this.c, new Digit1(this.d)];
            } else {
              return [new Digit3(this.a, this.b, this.c), this.d, Empty];
            }
          }
        };

        Digit4.prototype.reverse = function() {
          return new Digit4(rev(this.d), rev(this.c), rev(this.b), rev(this.a));
        };

        return Digit4;

      })();
      Empty = {
        isEmpty: function() {
          return true;
        },
        reduceLeft: function(z, op) {
          return z;
        },
        reduceRight: function(op, z) {
          return z;
        },
        after: function(a) {
          return new Single(a);
        },
        before: function(a) {
          return new Single(a);
        },
        first: function() {},
        last: function() {},
        rest: function() {},
        init: function() {},
        concat: function(t) {
          return t;
        },
        measure: function() {
          return norm();
        },
        reverse: function() {
          return this;
        }
      };
      empty = new Instance(Empty);
      Single = (function() {

        function Single(a) {
          this.a = a;
        }

        Single.prototype.isEmpty = function() {
          return false;
        };

        Single.prototype.reduceLeft = function(z, op) {
          return op(z, this.a);
        };

        Single.prototype.reduceRight = function(op, z) {
          return op(this.a, z);
        };

        Single.prototype.after = function(x) {
          return new Deep(new Digit1(x), (function() {
            return Empty;
          }), new Digit1(this.a));
        };

        Single.prototype.before = function(x) {
          return new Deep(new Digit1(this.a), (function() {
            return Empty;
          }), new Digit1(x));
        };

        Single.prototype.first = function() {
          return this.a;
        };

        Single.prototype.last = function() {
          return this.a;
        };

        Single.prototype.rest = function() {
          return Empty;
        };

        Single.prototype.init = function() {
          return Empty;
        };

        Single.prototype.concat = function(t) {
          return t.after(this.a);
        };

        Single.prototype.measure = function() {
          return norm(this.a);
        };

        Single.prototype.split = function(p, i) {
          return [Empty, this.a, Empty];
        };

        Single.prototype.reverse = function() {
          return this;
        };

        return Single;

      })();
      Deep = (function() {
        var app3, asSeq, asTree, deepL, deepR, nodes, reduceLeft, reduceRight;

        reduceLeft = function(op) {
          return function(z, x) {
            return x.reduceLeft(z, op);
          };
        };

        reduceRight = function(op) {
          return function(x, z) {
            return x.reduceRight(op, z);
          };
        };

        asTree = function(s) {
          return s.reduceLeft(Empty, function(a, b) {
            return a.before(b);
          });
        };

        asSeq = function(s) {
          return s.reduceRight((function(a, b) {
            return seq.conj(a, function() {
              return b;
            });
          }), null);
        };

        function Deep(l, m, r) {
          this.l = l;
          this.m = m;
          this.r = r;
        }

        Deep.prototype.isEmpty = function() {
          return false;
        };

        Deep.prototype.measure = function() {
          var val;
          val = norm(this.l, this.m(), this.r);
          return (this.measure = function() {
            return val;
          })();
        };

        Deep.prototype.reduceLeft = function(z, op0) {
          var op1, op2;
          op1 = reduceLeft(op0);
          op2 = reduceLeft(op1);
          return op1(op2(op1(z, this.l), this.m()), this.r);
        };

        Deep.prototype.reduceRight = function(op0, z) {
          var op1, op2;
          op1 = reduceRight(op0);
          op2 = reduceRight(op1);
          return op1(this.l, op2(this.m(), op1(this.r, z)));
        };

        Deep.prototype.after = function(x) {
          var a, b, c, d, l, _ref10,
            _this = this;
          if (this.l.constructor === Digit4) {
            _ref10 = this.l, a = _ref10.a, b = _ref10.b, c = _ref10.c, d = _ref10.d;
            l = new Digit2(x, a);
            return new Deep(l, suspend(function() {
              return _this.m().after(new Node3(b, c, d));
            }), this.r);
          } else {
            return new Deep(this.l.after(x), this.m, this.r);
          }
        };

        Deep.prototype.before = function(x) {
          var a, b, c, d, r, _ref10,
            _this = this;
          if (this.r.constructor === Digit4) {
            _ref10 = this.r, a = _ref10.a, b = _ref10.b, c = _ref10.c, d = _ref10.d;
            r = new Digit2(d, x);
            return new Deep(this.l, suspend(function() {
              return _this.m().before(new Node3(a, b, c));
            }), r);
          } else {
            return new Deep(this.l, this.m, this.r.before(x));
          }
        };

        Deep.prototype.first = function() {
          return this.l.first();
        };

        Deep.prototype.last = function() {
          return this.r.last();
        };

        deepL = function(l, m, r) {
          var _this = this;
          if (l === Empty) {
            if (m() === Empty) {
              return asTree(r);
            } else {
              return new Deep(m().first().asDigit(), suspend(function() {
                return m().rest();
              }), r);
            }
          } else {
            return new Deep(l, m, r);
          }
        };

        deepR = function(l, m, r) {
          var _this = this;
          if (r === Empty) {
            if (m() === Empty) {
              return asTree(l);
            } else {
              return new Deep(l, suspend(function() {
                return m().init();
              }), m().last().asDigit());
            }
          } else {
            return new Deep(l, m, r);
          }
        };

        Deep.prototype.rest = function() {
          var _this = this;
          return deepL(this.l.rest(), suspend(function() {
            return _this.m();
          }), this.r);
        };

        Deep.prototype.init = function() {
          var _this = this;
          return deepR(this.l, suspend(function() {
            return _this.m();
          }), this.r.init());
        };

        nodes = function(n, s) {
          if (n === 0) {
            return null;
          } else if (n === 1 || n < 0) {
            throw new Error("this should not happen");
          } else if (n === 2 || n % 3 === 1) {
            return seq.conj((function(func, args, ctor) {
              ctor.prototype = func.prototype;
              var child = new ctor, result = func.apply(child, args);
              return typeof result === "object" ? result : child;
            })(Node2, s.take(2).into([]), function() {}), function() {
              return nodes(n - 2, s.drop(2));
            });
          } else {
            return seq.conj((function(func, args, ctor) {
              ctor.prototype = func.prototype;
              var child = new ctor, result = func.apply(child, args);
              return typeof result === "object" ? result : child;
            })(Node3, s.take(3).into([]), function() {}), function() {
              return nodes(n - 3, s.drop(3));
            });
          }
        };

        app3 = function(tLeft, list, tRight) {
          var tmp;
          if (tLeft === Empty) {
            return seq.reduce(seq.reverse(list), tRight, function(t, x) {
              return t.after(x);
            });
          } else if (tRight === Empty) {
            return seq.reduce(list, tLeft, function(t, x) {
              return t.before(x);
            });
          } else if (tLeft.constructor === Single) {
            return app3(Empty, list, tRight).after(tLeft.a);
          } else if (tRight.constructor === Single) {
            return app3(tLeft, list, Empty).before(tRight.a);
          } else {
            tmp = seq.flatten([asSeq(tLeft.r), list, asSeq(tRight.l)]);
            s = nodes(tmp.size(), tmp);
            return new Deep(tLeft.l, suspend(function() {
              return app3(tLeft.m(), s, tRight.m());
            }), tRight.r);
          }
        };

        Deep.prototype.concat = function(t) {
          return app3(this, null, t);
        };

        Deep.prototype.split = function(p, i) {
          var i1, i2, l, ml, mr, r, x, xs, _ref10, _ref11, _ref12, _ref13,
            _this = this;
          i1 = measure.sum(i, norm(this.l));
          if (p(i1)) {
            _ref10 = this.l.split(p, i), l = _ref10[0], x = _ref10[1], r = _ref10[2];
            return [
              asTree(l), x, deepL(r, suspend(function() {
                return _this.m();
              }), this.r)
            ];
          } else {
            i2 = measure.sum(i1, norm(this.m()));
            if (p(i2)) {
              _ref11 = this.m().split(p, i1), ml = _ref11[0], xs = _ref11[1], mr = _ref11[2];
              _ref12 = xs.asDigit().split(p, measure.sum(i1, norm(ml))), l = _ref12[0], x = _ref12[1], r = _ref12[2];
              return [
                deepR(this.l, (function() {
                  return ml;
                }), l), x, deepL(r, (function() {
                  return mr;
                }), this.r)
              ];
            } else {
              _ref13 = this.r.split(p, i2), l = _ref13[0], x = _ref13[1], r = _ref13[2];
              return [
                deepR(this.l, suspend(function() {
                  return _this.m();
                }), l), x, asTree(r)
              ];
            }
          }
        };

        Deep.prototype.reverse = function() {
          var _this = this;
          return new Deep(this.r.reverse(), suspend(function() {
            return _this.m().reverse();
          }), this.l.reverse());
        };

        return Deep;

      })();
      internal = [Node2, Node3, Digit1, Digit2, Digit3, Digit4, Single, Deep];
    }

    return FingerTreeType;

  })();

  SizeMeasure = {
    empty: 0,
    single: function(x) {
      return 1;
    },
    sum: function(a, b) {
      return a + b;
    }
  };

  CountedExtensions = (function(_super) {

    __extends(CountedExtensions, _super);

    function CountedExtensions() {
      CountedExtensions.__super__.constructor.apply(this, arguments);
    }

    CountedExtensions.prototype.size = function() {
      return this.measure();
    };

    CountedExtensions.prototype.get = function(i) {
      return this.find(function(m) {
        return m > i;
      });
    };

    CountedExtensions.prototype.splitAt = function(i) {
      var l, r, x, _ref10;
      _ref10 = this.split(function(m) {
        return m > i;
      }), l = _ref10[0], x = _ref10[1], r = _ref10[2];
      return [l, r.after(x)];
    };

    return CountedExtensions;

  })(DefaultExtensions);

  CountedSeq = new FingerTreeType(SizeMeasure, CountedExtensions);

  OrderMeasure = {
    empty: void 0,
    single: function(x) {
      return x;
    },
    sum: function(a, b) {
      if (b != null) {
        return b;
      } else {
        return a;
      }
    }
  };

  SortedExtensions = function(less, extensions) {
    return (function(_super) {
      var after, before, concat, intersect, merge;

      __extends(_Class, _super);

      function _Class() {
        _Class.__super__.constructor.apply(this, arguments);
      }

      after = function(s, k) {
        if (k === void 0) {
          return s;
        } else {
          return new s.constructor(s.data.after(k));
        }
      };

      before = function(s, k) {
        if (k === void 0) {
          return s;
        } else {
          return new s.constructor(s.data.before(k));
        }
      };

      concat = function(s, t) {
        return new s.constructor(s.data.concat(t.data));
      };

      _Class.prototype.partition = function(k) {
        var l, r, x, _ref10;
        _ref10 = this.split(function(m) {
          return !less(m, k);
        }), l = _ref10[0], x = _ref10[1], r = _ref10[2];
        return [l, after(r, x)];
      };

      _Class.prototype.insert = function(k) {
        var l, r, _ref10;
        _ref10 = this.partition(k), l = _ref10[0], r = _ref10[1];
        return concat(l, after(r, k));
      };

      _Class.prototype.deleteAll = function(k) {
        var l, r, _ref10;
        _ref10 = this.partition(k), l = _ref10[0], r = _ref10[1];
        return concat(l, r.dropUntil(function(m) {
          return less(k, m);
        }));
      };

      merge = function(s, t1, t2) {
        var k, l, r, x, _ref10;
        if (t2.isEmpty()) {
          return concat(s, t1);
        } else {
          k = t2.first();
          _ref10 = t1.split(function(m) {
            return less(k, m);
          }), l = _ref10[0], x = _ref10[1], r = _ref10[2];
          return function() {
            var a;
            a = concat(s, before(l, k));
            return merge(a, t2.rest(), after(r, x));
          };
        }
      };

      _Class.prototype.merge = function(other) {
        return bounce(merge(this.empty(), this, other));
      };

      intersect = function(s, t1, t2) {
        var k, l, r, x, _ref10;
        if (t2.isEmpty()) {
          return s;
        } else {
          k = t2.first();
          _ref10 = t1.split(function(m) {
            return !less(m, k);
          }), l = _ref10[0], x = _ref10[1], r = _ref10[2];
          if (less(k, x)) {
            return function() {
              return intersect(s, t2.rest(), after(r, x));
            };
          } else {
            return function() {
              return intersect(before(s, x), t2.rest(), r);
            };
          }
        }
      };

      _Class.prototype.intersect = function(other) {
        return bounce(intersect(this.empty(), this, other));
      };

      _Class.prototype.plus = _Class.prototype.insert;

      return _Class;

    })(extensions);
  };

  SortedSeqType = (function(_super) {

    __extends(SortedSeqType, _super);

    function SortedSeqType(less, extensions) {
      if (less == null) {
        less = (function(a, b) {
          return a < b;
        });
      }
      if (extensions == null) extensions = Void;
      SortedSeqType.__super__.constructor.call(this, OrderMeasure, SortedExtensions(less, extensions));
    }

    return SortedSeqType;

  })(FingerTreeType);

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref10 = this.pazy) != null ? _ref10 : this.pazy = {};
  }

  exports.FingerTreeType = FingerTreeType;

  exports.CountedSeq = CountedSeq;

  exports.SortedSeqType = SortedSeqType;

  exports.SortedSeq = new SortedSeqType();

  if (typeof require !== 'undefined') {
    bounce = require('functional').bounce;
    HashMap = require('indexed').HashMap;
  } else {
    _ref11 = this.pazy, bounce = _ref11.bounce, HashMap = _ref11.HashMap;
  }

  Partition = (function() {
    var make;

    function Partition() {
      this.rank = new HashMap();
      this.parent = new HashMap();
    }

    make = function(rank, parent) {
      var p;
      p = new Partition();
      p.rank = rank;
      p.parent = parent;
      return p;
    };

    Partition.prototype.find = function(x) {
      var flatten, root, seek,
        _this = this;
      if (!(this.parent.get(x) != null)) {
        this.parent = this.parent.plus([x, x]);
        this.rank = this.rank.plus([x, 0]);
        return x;
      } else {
        seek = function(y) {
          var z;
          z = _this.parent.get(y);
          if (z === y) {
            return z;
          } else {
            return function() {
              return seek(z);
            };
          }
        };
        root = bounce(seek(x));
        flatten = function(y) {
          var z;
          z = _this.parent.get(y);
          _this.parent = _this.parent.plus([y, root]);
          if (z !== y) {
            return function() {
              return flatten(z);
            };
          }
        };
        bounce(flatten(x));
        return root;
      }
    };

    Partition.prototype.union = function(x, y) {
      var xRank, xRoot, yRank, yRoot;
      xRoot = this.find(x);
      yRoot = this.find(y);
      if (xRoot === yRoot) {
        return this;
      } else {
        xRank = this.rank.get(xRoot);
        yRank = this.rank.get(yRoot);
        if (xRank < yRank) {
          return make(this.rank, this.parent.plus([xRoot, yRoot]));
        } else if (xRank > yRank) {
          return make(this.rank, this.parent.plus([yRoot, xRoot]));
        } else {
          return make(this.rank.plus([xRoot, xRank + 1]), this.parent.plus([yRoot, xRoot]));
        }
      }
    };

    return Partition;

  })();

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref12 = this.pazy) != null ? _ref12 : this.pazy = {};
  }

  exports.Partition = Partition;

  if (typeof require !== 'undefined') {
    seq = require('sequence').seq;
  } else {
    seq = this.pazy.seq;
  }

  Stack = (function() {

    function Stack(s) {
      this.s = s;
    }

    Stack.prototype.push = function(x) {
      var _this = this;
      return new Stack(seq.conj(x, function() {
        return _this.s;
      }));
    };

    Stack.prototype.first = function() {
      var _ref13;
      return (_ref13 = this.s) != null ? _ref13.first() : void 0;
    };

    Stack.prototype.rest = function() {
      var _ref13;
      return new Stack((_ref13 = this.s) != null ? _ref13.rest() : void 0);
    };

    Stack.prototype.toSeq = function() {
      return this.s;
    };

    return Stack;

  })();

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref13 = this.pazy) != null ? _ref13 : this.pazy = {};
  }

  exports.Stack = Stack;

  if (typeof require !== 'undefined') {
    seq = require('sequence').seq;
  } else {
    seq = this.pazy.seq;
  }

  Queue = (function() {
    var rotate;

    function Queue(f, r, s) {
      var _ref14;
      if (s) {
        _ref14 = [f, r, s.rest()], this.front = _ref14[0], this.rear = _ref14[1], this.schedule = _ref14[2];
      } else if (f || r) {
        this.front = this.schedule = rotate(f, r, null);
        this.rear = null;
      } else {
        this.front = this.rear = this.schedule = null;
      }
    }

    rotate = function(f, r, a) {
      var a1;
      a1 = seq.conj(r.first(), (function() {
        return a;
      }));
      if (f) {
        return seq.conj(f.first(), (function() {
          return rotate(f.rest(), r.rest(), a1);
        }));
      } else {
        return a1;
      }
    };

    Queue.prototype.push = function(x) {
      var _this = this;
      return new Queue(this.front, seq.conj(x, (function() {
        return _this.rear;
      })), this.schedule);
    };

    Queue.prototype.first = function() {
      var _ref14;
      return (_ref14 = this.front) != null ? _ref14.first() : void 0;
    };

    Queue.prototype.rest = function() {
      var _ref14;
      return new Queue((_ref14 = this.front) != null ? _ref14.rest() : void 0, this.rear, this.schedule);
    };

    Queue.prototype.toSeq = function() {
      return seq.concat(this.front, seq.reverse(this.rear));
    };

    return Queue;

  })();

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref14 = this.pazy) != null ? _ref14 : this.pazy = {};
  }

  exports.Queue = Queue;

  if (typeof require !== 'undefined') {
    bounce = require('functional').bounce;
    seq = require('sequence').seq;
  } else {
    _ref15 = this.pazy, bounce = _ref15.bounce, seq = _ref15.seq;
  }

  quicktest = (typeof module !== "undefined" && module !== null) && !module.parent;

  log = quicktest ? function(str) {
    return console.log(str);
  } : function(str) {};

  BASE_LENGTH = quicktest ? 4 : seq.from(1).map(function(n) {
    return 2 * n;
  }).takeWhile(function(n) {
    var b;
    b = Math.pow(10, n);
    return 2 * b - 2 !== 2 * b - 1 && -2 * b + 2 !== -2 * b + 1;
  }).last();

  BASE = Math.pow(10, BASE_LENGTH);

  HALFBASE = Math.sqrt(BASE);

  asNum = function(n) {
    if (Math.abs(n) < BASE) {
      return new CheckedInt(n);
    } else {
      return LongInt.fromNative(n);
    }
  };

  num = function(n) {
    if (n == null) n = 0;
    switch (typeof n) {
      case 'number':
        return num.fromNative(n);
      case 'string':
        return num.parse(n);
      default:
        if (n instanceof NumberBase) {
          return n;
        } else {
          throw new Error("expected a number, got " + n);
        }
    }
  };

  num.fromNative = function(n) {
    if (n !== Math.floor(n)) throw new Error("expected an integer, got " + n);
    return asNum(n);
  };

  num.parse = function(n) {
    var m, parsed, _ref16;
    if (!/^[+-]?\d+$/.test(n)) {
      throw new Error("expected an integer literal, got '" + n + "'");
    }
    _ref16 = (function() {
      switch (n[0]) {
        case '-':
          return [-1, n.slice(1)];
        case '+':
          return [1, n.slice(1)];
        default:
          return [1, n];
      }
    })(), s = _ref16[0], m = _ref16[1];
    if (m.length <= BASE_LENGTH) {
      return new CheckedInt(parseInt(n));
    } else {
      parsed = function(to) {
        var from;
        if (to > 0) {
          from = Math.max(0, to - BASE_LENGTH);
          return seq.conj(parseInt(m.slice(from, to)), function() {
            return parsed(from);
          });
        } else {
          return null;
        }
      };
      return new LongInt(s, parsed(m.length));
    }
  };

  NumberBase = (function() {
    var downcast, makeNum, name, operator, upcast, _fn, _fn2, _i, _j, _len, _len2, _ref16, _ref17;

    function NumberBase() {}

    makeNum = function(n) {
      if (n instanceof NumberBase) {
        return n;
      } else if (typeof n === 'number') {
        if (Math.floor(n) === n) {
          if (Math.abs(n) < BASE) {
            return new CheckedInt(n);
          } else {
            return LongInt.fromNative(n);
          }
        } else {
          throw new Error("expected an integer, got " + n);
        }
      } else {
        throw new Error("expected a number, got " + n);
      }
    };

    upcast = function(a, b) {
      var op1, op2, out, tp1, tp2, _ref16, _ref17;
      _ref16 = [makeNum(a), makeNum(b)], op1 = _ref16[0], op2 = _ref16[1];
      out = (function() {
        switch (op1.constructor) {
          case CheckedInt:
            switch (op2.constructor) {
              case CheckedInt:
                return [op1, op2];
              case LongInt:
                return [LongInt.fromNative(op1.val), op2];
              case Fraction:
                return [new Fraction(op1, num(1)), op2];
            }
            break;
          case LongInt:
            switch (op2.constructor) {
              case CheckedInt:
                return [op1, LongInt.fromNative(op2.val)];
              case LongInt:
                return [op1, op2];
              case Fraction:
                return [new Fraction(op1, num(1)), op2];
            }
            break;
          case Fraction:
            switch (op2.constructor) {
              case CheckedInt:
              case LongInt:
                return [op1, new Fraction(op2, num(1))];
              case Fraction:
                return [op1, op2];
            }
        }
      })();
      if (out) {
        return out;
      } else {
        _ref17 = [op1.constructor, op2.constructor], tp1 = _ref17[0], tp2 = _ref17[1];
        throw new Error("operands of types " + tp1 + " and " + tp2 + " not supported");
      }
    };

    downcast = function(x) {
      if (x instanceof LongInt && x.lt(BASE)) {
        if (x.digits != null) {
          return new CheckedInt(x.digits.first() * x.sign);
        } else {
          return new CheckedInt(0);
        }
      } else if (x instanceof Fraction && x.denom.eq(1)) {
        return x.numer;
      } else {
        return x;
      }
    };

    operator = function(name, f) {
      num[name] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return f.call.apply(f, [num].concat(__slice.call(args)));
      };
      return NumberBase.prototype[name] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return num[name].apply(num, [this].concat(__slice.call(args)));
      };
    };

    _ref16 = ['cmp', 'plus', 'minus', 'times', 'div', 'idiv', 'mod', 'gcd'];
    _fn = function(name) {
      var namex;
      namex = "" + name + "__";
      return operator(name, function(a, b) {
        var x, y, _ref17;
        _ref17 = upcast(a, b), x = _ref17[0], y = _ref17[1];
        return downcast(x[namex](y));
      });
    };
    for (_i = 0, _len = _ref16.length; _i < _len; _i++) {
      name = _ref16[_i];
      _fn(name);
    }

    NumberBase.prototype.div__ = function(other) {
      return Fraction.normalized(this, other);
    };

    NumberBase.prototype.gcd__ = function(other) {
      var step, x, y, _ref17;
      step = function(a, b) {
        if (b.isPos()) {
          return function() {
            return step(b, a.mod(b));
          };
        } else {
          return a;
        }
      };
      _ref17 = [this.abs(), other.abs()], x = _ref17[0], y = _ref17[1];
      if (x.gt(y)) {
        return bounce(step(x, y));
      } else {
        return bounce(step(x, y));
      }
    };

    operator('lt', function(a, b) {
      return num.cmp(a, b) < 0;
    });

    operator('gt', function(a, b) {
      return num.cmp(a, b) > 0;
    });

    operator('eq', function(a, b) {
      return num.cmp(a, b) === 0;
    });

    operator('equals', function(a, b) {
      return num.cmp(a, b) === 0;
    });

    _ref17 = ['neg', 'abs', 'sgn', 'isPos', 'isNeg', 'isZero', 'isEven', 'isOdd'];
    _fn2 = function(name) {
      var namex;
      namex = "" + name + "__";
      return operator(name, function(a) {
        return makeNum(a)[namex]();
      });
    };
    for (_j = 0, _len2 = _ref17.length; _j < _len2; _j++) {
      name = _ref17[_j];
      _fn2(name);
    }

    operator('isqrt', function(a) {
      return downcast(makeNum(a)['isqrt__']());
    });

    operator('pow', function(a, b) {
      var step;
      step = function(p, r, s) {
        if (s.isPos()) {
          if (s.isOdd() > 0) {
            return function() {
              return step(p.times(r), r, s.minus(1));
            };
          } else {
            return function() {
              return step(p, r.times(r), s.idiv(2));
            };
          }
        } else {
          return p;
        }
      };
      return downcast(bounce(step(makeNum(1), makeNum(a), makeNum(b))));
    });

    return NumberBase;

  })();

  CheckedInt = (function(_super) {

    __extends(CheckedInt, _super);

    function CheckedInt(val) {
      this.val = val != null ? val : 0;
    }

    CheckedInt.prototype.neg__ = function() {
      return new CheckedInt(-this.val);
    };

    CheckedInt.prototype.abs__ = function() {
      return new CheckedInt(Math.abs(this.val));
    };

    CheckedInt.prototype.sgn__ = function() {
      if (this.val < 0) {
        return -1;
      } else if (this.val > 0) {
        return 1;
      } else {
        return 0;
      }
    };

    CheckedInt.prototype.isPos__ = function() {
      return this.val > 0;
    };

    CheckedInt.prototype.isNeg__ = function() {
      return this.val < 0;
    };

    CheckedInt.prototype.isZero__ = function() {
      return this.val === 0;
    };

    CheckedInt.prototype.isEven__ = function() {
      return this.val % 2 === 0;
    };

    CheckedInt.prototype.isOdd__ = function() {
      return this.val % 2 !== 0;
    };

    CheckedInt.prototype.isqrt__ = function() {
      return new CheckedInt(Math.floor(Math.sqrt(this.val)));
    };

    CheckedInt.prototype.cmp__ = function(other) {
      if (this.val < other.val) {
        return -1;
      } else if (this.val > other.val) {
        return 1;
      } else {
        return 0;
      }
    };

    CheckedInt.prototype.plus__ = function(other) {
      return asNum(this.val + other.val);
    };

    CheckedInt.prototype.minus__ = function(other) {
      return asNum(this.val - other.val);
    };

    CheckedInt.prototype.times__ = function(other) {
      var x;
      x = this.val * other.val;
      if (Math.abs(x) < BASE) {
        return new CheckedInt(x);
      } else {
        return LongInt.fromNative(this.val).times(other);
      }
    };

    CheckedInt.prototype.idiv__ = function(x) {
      return new CheckedInt(Math.floor(this.val / x.val));
    };

    CheckedInt.prototype.mod__ = function(x) {
      return new CheckedInt(this.val % x.val);
    };

    CheckedInt.prototype.toString = function() {
      return "" + this.val;
    };

    CheckedInt.prototype.toNative = function() {
      return this.val;
    };

    return CheckedInt;

  })(NumberBase);

  LongInt = (function(_super) {
    var ZERO, add, cleanup, cmp, digitTimesDigit, dump, idiv, idivmod, isqrt, makeDigits, mod, mul, rdump, seqTimesDigit, split, sub, zeroes;

    __extends(LongInt, _super);

    function LongInt(sign, digits) {
      var _ref16;
      this.digits = digits;
      this.sign = this.digits != null ? sign : 0;
      this.first = ((_ref16 = this.digits) != null ? _ref16.first() : void 0) || 0;
    }

    LongInt.prototype.neg__ = function() {
      return new LongInt(-this.sign, this.digits);
    };

    LongInt.prototype.abs__ = function() {
      return new LongInt(1, this.digits);
    };

    LongInt.prototype.sgn__ = function() {
      return this.sign;
    };

    LongInt.prototype.isPos__ = function() {
      return this.sign > 0;
    };

    LongInt.prototype.isNeg__ = function() {
      return this.sign < 0;
    };

    LongInt.prototype.isZero__ = function() {
      return this.sign === 0;
    };

    LongInt.prototype.isEven__ = function() {
      return this.first % 2 === 0;
    };

    LongInt.prototype.isOdd__ = function() {
      return this.first % 2 !== 0;
    };

    zeroes = BASE.toString().slice(1);

    rdump = function(s) {
      if (s) {
        return s.map(function(t) {
          return "" + zeroes.slice(t.toString().length) + t;
        }).into([]).join('|');
      } else {
        return '[]';
      }
    };

    dump = function(s) {
      return rdump(s != null ? s.reverse() : void 0);
    };

    ZERO = seq([0]);

    cleanup = function(s) {
      var _ref16, _ref17;
      return (s != null ? (_ref16 = s.reverse()) != null ? (_ref17 = _ref16.dropWhile(function(x) {
        return x === 0;
      })) != null ? _ref17.reverse() : void 0 : void 0 : void 0) || null;
    };

    isqrt = function(s) {
      var n, step;
      n = s.size();
      step = function(r) {
        var rn;
        rn = seq(idiv(add(r, idiv(s, r)), seq([2])));
        if (cmp(r, rn)) {
          return function() {
            return step(rn);
          };
        } else {
          return rn;
        }
      };
      return bounce(step(s.take(n >> 1)));
    };

    LongInt.prototype.isqrt__ = function() {
      if (this.isZero()) {
        return asNum(0);
      } else if (this.isPos()) {
        return new LongInt(1, isqrt(this.digits));
      } else {
        throw new Error("expected a non-negative number, got " + this);
      }
    };

    cmp = function(r, s) {
      var _ref16, _ref17, _ref18;
      return ((_ref16 = seq.sub(r, s)) != null ? (_ref17 = _ref16.reverse()) != null ? (_ref18 = _ref17.dropWhile(function(x) {
        return x === 0;
      })) != null ? _ref18.first() : void 0 : void 0 : void 0) || 0;
    };

    LongInt.prototype.cmp__ = function(x) {
      if (this.isZero()) {
        return -x.sign;
      } else if (x.isZero()) {
        return this.sign;
      } else if (this.sign !== x.sign) {
        return this.sign;
      } else {
        return this.sign * cmp(this.digits, x.digits);
      }
    };

    add = function(r, s, c) {
      var carry, digit, r_, s_, x, _ref16, _ref17;
      if (c == null) c = 0;
      if (c || (r && s)) {
        _ref16 = [r || ZERO, s || ZERO], r_ = _ref16[0], s_ = _ref16[1];
        x = r_.first() + s_.first() + c;
        _ref17 = x >= BASE ? [x - BASE, 1] : [x, 0], digit = _ref17[0], carry = _ref17[1];
        return seq.conj(digit, function() {
          return add(r_.rest(), s_.rest(), carry);
        });
      } else {
        return s || r;
      }
    };

    LongInt.prototype.plus__ = function(x) {
      if (this.sign !== x.sign) {
        return this.minus(x.neg());
      } else {
        return new LongInt(this.sign, add(this.digits, x.digits));
      }
    };

    sub = function(r, s) {
      var step;
      step = function(r, s, b) {
        var borrow, digit, r_, s_, x, _ref16, _ref17;
        if (b == null) b = 0;
        if (b || (r && s)) {
          _ref16 = [r || ZERO, s || ZERO], r_ = _ref16[0], s_ = _ref16[1];
          x = r_.first() - s_.first() - b;
          _ref17 = x < 0 ? [x + BASE, 1] : [x, 0], digit = _ref17[0], borrow = _ref17[1];
          return seq.conj(digit, function() {
            return step(r_.rest(), s_.rest(), borrow);
          });
        } else {
          return s || r;
        }
      };
      return cleanup(step(r, s));
    };

    LongInt.prototype.minus__ = function(x) {
      if (this.sign !== x.sign) {
        return this.plus(x.neg());
      } else if (cmp(this.digits, x.digits) < 0) {
        return new LongInt(-this.sign, sub(x.digits, this.digits));
      } else {
        return new LongInt(this.sign, sub(this.digits, x.digits));
      }
    };

    split = function(n) {
      return [n % HALFBASE, Math.floor(n / HALFBASE)];
    };

    digitTimesDigit = function(a, b) {
      var a0, a1, b0, b1, carry, lo, m0, m1, tmp, _ref16, _ref17, _ref18, _ref19;
      if (b < BASE / a) {
        return [a * b, 0];
      } else {
        _ref16 = split(a), a0 = _ref16[0], a1 = _ref16[1];
        _ref17 = split(b), b0 = _ref17[0], b1 = _ref17[1];
        _ref18 = split(a0 * b1 + b0 * a1), m0 = _ref18[0], m1 = _ref18[1];
        tmp = a0 * b0 + m0 * HALFBASE;
        _ref19 = tmp < BASE ? [tmp, 0] : [tmp - BASE, 1], lo = _ref19[0], carry = _ref19[1];
        return [lo, a1 * b1 + m1 + carry];
      }
    };

    seqTimesDigit = function(s, d, c) {
      var hi, lo, s_, _ref16;
      if (c == null) c = 0;
      if (c || s) {
        s_ = s || ZERO;
        _ref16 = digitTimesDigit(d, s_.first()), lo = _ref16[0], hi = _ref16[1];
        return seq.conj(lo + c, function() {
          return seqTimesDigit(s_.rest(), d, hi);
        });
      }
    };

    mul = function(a, b) {
      var step;
      step = function(r, a, b) {
        var t;
        if (a) {
          t = add(r, seqTimesDigit(b, a.first())) || ZERO;
          return seq.conj(t.first(), function() {
            return step(t.rest(), a.rest(), b);
          });
        } else {
          return r;
        }
      };
      return step(null, a, b);
    };

    LongInt.prototype.times__ = function(x) {
      return new LongInt(this.sign * x.sign, mul(this.digits, x.digits));
    };

    idivmod = function(r, s) {
      var d, m, r_, s_, scale, step, x, _ref16, _ref17;
      if (!cleanup(r)) return [ZERO, ZERO];
      scale = Math.floor(BASE / (s.last() + 1));
      _ref16 = (function() {
        var _i, _len, _ref16, _results;
        _ref16 = [r, s];
        _results = [];
        for (_i = 0, _len = _ref16.length; _i < _len; _i++) {
          x = _ref16[_i];
          _results.push(seq(seqTimesDigit(x, scale)));
        }
        return _results;
      })(), r_ = _ref16[0], s_ = _ref16[1];
      _ref17 = [s_.size(), s_.last() + 1], m = _ref17[0], d = _ref17[1];
      step = function(q, h, t) {
        var f, n;
        f = (h != null ? h.size() : void 0) < m ? 0 : (n = ((h != null ? h.last() : void 0) * ((h != null ? h.size() : void 0) > m ? BASE : 1)) || 0, (Math.floor(n / d)) || (cmp(h, s_) >= 0 ? 1 : 0));
        if (f) {
          return function() {
            return step(add(q, seq.conj(f)), sub(h, seqTimesDigit(s_, f)), t);
          };
        } else if (t) {
          return function() {
            return step(seq.conj(0, function() {
              return q;
            }), seq.conj(t.first(), function() {
              return h;
            }), t.rest());
          };
        } else {
          return [cleanup(q), h && idiv(h, seq([scale]))];
        }
      };
      return bounce(step(null, null, r_ != null ? r_.reverse() : void 0));
    };

    idiv = function(r, s) {
      return idivmod(r, s)[0];
    };

    mod = function(r, s) {
      return idivmod(r, s)[1];
    };

    LongInt.prototype.idiv__ = function(x) {
      var d;
      d = cmp(this.digits, x.digits);
      if (d < 0) {
        return asNum(0);
      } else if (d === 0) {
        return asNum(this.sign * x.sign);
      } else {
        return new LongInt(this.sign * x.sign, idiv(this.digits, x.digits));
      }
    };

    LongInt.prototype.mod__ = function(x) {
      var d;
      d = cmp(this.digits, x.digits);
      if (d < 0) {
        return this;
      } else if (d === 0) {
        return asNum(0);
      } else {
        return new LongInt(this.sign * x.sign, mod(this.digits, x.digits));
      }
    };

    LongInt.prototype.toString = function() {
      var parts, rest, sign, _ref16, _ref17, _ref18, _ref19;
      parts = (_ref16 = this.digits) != null ? (_ref17 = _ref16.reverse()) != null ? (_ref18 = _ref17.dropWhile(function(d) {
        return d === 0;
      })) != null ? _ref18.map(function(d) {
        return d.toString();
      }) : void 0 : void 0 : void 0;
      if (parts) {
        sign = this.isNeg() ? '-' : '';
        rest = (_ref19 = parts.rest()) != null ? _ref19.map(function(t) {
          return "" + zeroes.slice(t.length) + t;
        }) : void 0;
        return sign + parts.first() + (rest != null ? rest.join('') : '');
      } else {
        return '0';
      }
    };

    LongInt.prototype.toNative = function() {
      var rev, step, _ref16, _ref17;
      step = function(n, s) {
        if (s) {
          return function() {
            return step(n * BASE + s.first(), s.rest());
          };
        } else {
          return n;
        }
      };
      rev = (_ref16 = this.digits) != null ? (_ref17 = _ref16.reverse()) != null ? _ref17.dropWhile(function(d) {
        return d === 0;
      }) : void 0 : void 0;
      return this.sign * bounce(step(0, rev));
    };

    makeDigits = function(m) {
      if (m) {
        return seq.conj(m % BASE, function() {
          return makeDigits(Math.floor(m / BASE));
        });
      } else {
        return null;
      }
    };

    LongInt.fromNative = function(n) {
      if (n < 0) {
        return new LongInt(-1, makeDigits(-n));
      } else if (n > 0) {
        return new LongInt(1, makeDigits(n));
      } else {
        return new LongInt(0, null);
      }
    };

    return LongInt;

  })(NumberBase);

  Fraction = (function(_super) {

    __extends(Fraction, _super);

    function Fraction(numer, denom) {
      this.numer = numer;
      this.denom = denom;
    }

    Fraction.normalized = function(n, d) {
      var a;
      if (d.eq(0)) {
        throw new Error("expected a non-zero denominator, got " + d);
      } else if (d.lt(0)) {
        return Fraction.normalized(n.neg(), d.neg());
      } else {
        a = num.gcd(n, d);
        return new Fraction(n.idiv(a), d.idiv(a));
      }
    };

    Fraction.prototype.neg__ = function() {
      return new Fraction(this.numer.neg(), this.denom);
    };

    Fraction.prototype.abs__ = function() {
      return new Fraction(this.numer.abs(), this.denom);
    };

    Fraction.prototype.sgn__ = function() {
      return this.numer.sgn();
    };

    Fraction.prototype.inv__ = function() {
      return Fraction.normalized(this.denom, this.numer);
    };

    Fraction.prototype.isPos__ = function() {
      return this.numer.isPos();
    };

    Fraction.prototype.isNeg__ = function() {
      return this.numer.isNeg();
    };

    Fraction.prototype.isZero__ = function() {
      return this.numer.isZero();
    };

    Fraction.prototype.isEven__ = function() {
      return this.denom.eq(1) && this.numer.isEven();
    };

    Fraction.prototype.isOdd__ = function() {
      return this.denom.eq(1) && this.numer.isOdd();
    };

    Fraction.prototype.isqrt__ = function() {
      return num.idiv(this.numer, this.denom).isqrt();
    };

    Fraction.prototype.cmp__ = function(x) {
      return this.minus__(x).numer.cmp(0);
    };

    Fraction.prototype.plus__ = function(x) {
      var a, t;
      a = num.gcd(this.denom, x.denom);
      s = num.idiv(x.denom, a);
      t = num.idiv(this.denom, a);
      return Fraction.normalized(s.times(this.numer).plus(t.times(x.numer)), s.times(this.denom));
    };

    Fraction.prototype.minus__ = function(x) {
      return this.plus__(x.neg__());
    };

    Fraction.prototype.times__ = function(x) {
      var a, b, d, n;
      a = num.gcd(this.numer, x.denom);
      b = num.gcd(this.denom, x.numer);
      n = this.numer.idiv(a).times(x.numer.idiv(b));
      d = this.denom.idiv(b).times(x.denom.idiv(a));
      return Fraction.normalized(n, d);
    };

    Fraction.prototype.div__ = function(x) {
      return this.times__(x.inv__());
    };

    Fraction.prototype.toString = function() {
      if (this.denom.eq(1)) {
        return "" + this.numer;
      } else {
        return "" + this.numer + "/" + this.denom;
      }
    };

    Fraction.prototype.toNative = function() {
      return this.numer.toNative() / this.denom.toNative();
    };

    return Fraction;

  })(NumberBase);

  if (typeof exports === "undefined" || exports === null) {
    exports = (_ref16 = this.pazy) != null ? _ref16 : this.pazy = {};
  }

  exports.num = num;

  if (quicktest) {
    show = require('testing').show;
    a = b = c = 0;
    log('');
    show(function() {
      return null;
    });
    show(function() {
      return;
    });
    log('');
    show(function() {
      return num(98).gcd(21);
    });
    show(function() {
      return num(77777).gcd(21);
    });
    log('');
    show(function() {
      return a = num(Math.pow(2, 13));
    });
    show(function() {
      return LongInt.fromNative(a.val);
    });
    show(function() {
      return a.plus(2);
    });
    show(function() {
      return a.times(1);
    });
    show(function() {
      return a.times(2);
    });
    show(function() {
      return a.plus(2000);
    });
    log('');
    show(function() {
      return num(-123456789000000);
    });
    show(function() {
      return num('-1234');
    });
    show(function() {
      return num('-123456789000000');
    });
    log('');
    show(function() {
      return num(123456789).plus(876543211);
    });
    show(function() {
      return num(123456789).minus(123450000);
    });
    show(function() {
      return num(123456789).minus(123456790);
    });
    show(function() {
      return num(123456789).minus(123456789);
    });
    show(function() {
      return num(123456789).plus(-123450000);
    });
    log('');
    show(function() {
      return num(12345).times(100001);
    });
    show(function() {
      return num(11111).times(9);
    });
    show(function() {
      return num(111).idiv(37);
    });
    show(function() {
      return num(111111).idiv(37);
    });
    show(function() {
      return num(111111111).idiv(37);
    });
    show(function() {
      return num(111111111).idiv(12345679);
    });
    show(function() {
      return num(99980001).idiv(49990001);
    });
    show(function() {
      return num(20001).idiv(10001);
    });
    log('');
    show(function() {
      return num(111).mod(37);
    });
    show(function() {
      return num(111112).mod(37);
    });
    show(function() {
      return num(111111111).mod(12345679);
    });
    log('');
    show(function() {
      return num(9801).isqrt();
    });
    show(function() {
      return num(998001).isqrt();
    });
    show(function() {
      return num(99980001).isqrt();
    });
    log('');
    show(function() {
      return num(10).pow(6);
    });
    show(function() {
      return num(2).pow(16);
    });
    log('');
    show(function() {
      return num.plus(123456789, 876543211);
    });
    show(function() {
      return num.isqrt(99980001);
    });
    show(function() {
      return num.pow(2, 16);
    });
    show(function() {
      return num.abs(-12345);
    });
    show(function() {
      return num.isZero(1);
    });
    show(function() {
      return num.isZero(123456);
    });
    show(function() {
      return num.isZero(0);
    });
    show(function() {
      return num.isNeg(0);
    });
    show(function() {
      return num.isNeg(-45);
    });
    show(function() {
      return num.isNeg(-12345);
    });
    show(function() {
      return num.isOdd(-12345);
    });
    log('');
    show(function() {
      return num.eq(8, num(111119).mod(37));
    });
    show(function() {
      return num.lt(65535, num.pow(2, 16));
    });
    show(function() {
      return num.gt(65535, num.pow(2, 16));
    });
    show(function() {
      return num.gt(65536, num.pow(2, 16));
    });
    show(function() {
      return num.gt(65537, num.pow(2, 16));
    });
    log('');
    show(function() {
      return num.div(2, 3);
    });
    show(function() {
      return num.div(9, 10).times(num.div(5, 21));
    });
    show(function() {
      return num.div(3, 5).minus(num.div(7, 11));
    });
    show(function() {
      return num.div(111111111, 12345679 * 2);
    });
    show(function() {
      return num.div(28, 3).isqrt();
    });
    show(function() {
      return num.div(1, 2).plus(num.div(1, 2));
    });
    show(function() {
      return num.div(2, 3).plus(num.div(4, 3));
    });
    show(function() {
      return num.div(2, 3).plus(1);
    });
    show(function() {
      return num.div(2, 3).div(2);
    });
  }

}).call(this);
