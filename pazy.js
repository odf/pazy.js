var ArrayNode, BASE, BitmapIndexedNode, Collection, CollisionNode, CountedExtensions, CountedSeq, DefaultExtensions, EmptyNode, FingerTreeType, HALFBASE, HashLeaf, HashLeafWithValue, HashMap, HashSet, IntLeaf, IntLeafWithValue, IntMap, IntSet, LongInt, ONE, OrderMeasure, Partition, ProxyNode, Queue, Rational, Sequence, SizeMeasure, SortedExtensions, SortedSeqType, Stack, TWO, Void, ZERO, a, a2, a3, add, b, c, cleanup, cmp, d, digitTimesDigit, div, divmod, dump, equalKeys, hashCode, log, mod, mul, pow, quicktest, rdump, recur, resolve, seqTimesDigit, split, sqrt, sub, suspend, util, _ref, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __indexOf = Array.prototype.indexOf || function(item) {
  for (var i = 0, l = this.length; i < l; i++) {
    if (this[i] === item) return i;
  }
  return -1;
};
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref = this.pazy) != null ? _ref : this.pazy = {};
};
exports.suspend = function(code) {
  var val;
  val = null;
  return function() {
    if (code) {
      val = code();
      code = null;
    }
    return val;
  };
};
exports.recur = function(code) {
  return {
    recur__: code
  };
};
exports.resolve = function(val) {
  while (val != null ? val.recur__ : void 0) {
    val = val.recur__();
  }
  return val;
};
exports.scope = function(args, f) {
  return f.apply(null, args);
};
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  _ref2 = require('functional'), recur = _ref2.recur, resolve = _ref2.resolve;
} else {
  _ref3 = this.pazy, recur = _ref3.recur, resolve = _ref3.resolve;
}
Sequence = (function() {
  var make;
  function Sequence(src) {
    var dummy, n, partial, seq;
    if (!(src != null)) {
      this.first = function() {};
      this.rest = function() {
        return null;
      };
    } else if (typeof src.toSeq === 'function') {
      seq = src.toSeq();
      if (seq != null) {
        this.first = function() {
          return seq.first();
        };
        this.rest = function() {
          return seq.rest();
        };
      } else {
        this.first = function() {};
        this.rest = function() {
          return null;
        };
      }
    } else if (typeof src.first === 'function' && typeof src.rest === 'function') {
      this.first = function() {
        return src.first();
      };
      this.rest = function() {
        return src.rest();
      };
    } else if (typeof src.length === 'number') {
      n = src.length;
      partial = function(i) {
        while (i < n && typeof src[i] === 'undefined') {
          i += 1;
        }
        if (i < n) {
          return Sequence.conj(src[i], function() {
            return partial(i + 1);
          });
        } else {
          return null;
        }
      };
      dummy = partial(0);
      if (dummy) {
        this.first = function() {
          return dummy.first();
        };
        this.rest = function() {
          return dummy.rest();
        };
      } else {
        this.first = function() {};
        this.rest = function() {
          return null;
        };
      }
    } else {
      throw new Error("cannot make a sequence from " + src);
    }
  }
  Sequence.accepts = function(src) {
    return !(src != null) || typeof src.toSeq === 'function' || (typeof src.first === 'function' && typeof src.rest === 'function') || typeof src.length === 'number';
  };
  Sequence.conj = function(first, rest, mode) {
    var r;
    if (rest == null) {
      rest = (function() {
        return null;
      });
    }
    if (mode == null) {
      mode = null;
    }
    if (mode === 'forced') {
      r = rest();
      return new Sequence({
        first: function() {
          return first;
        },
        rest: function() {
          return r;
        }
      });
    } else {
      return new Sequence({
        first: function() {
          return first;
        },
        rest: function() {
          var val;
          val = rest();
          return (this.rest = function() {
            return val;
          })();
        }
      });
    }
  };
  Sequence.from = function(start) {
    return Sequence.conj(start, __bind(function() {
      return this.from(start + 1);
    }, this));
  };
  Sequence.range = function(start, end) {
    return this.take__(this.from(start), end - start + 1);
  };
  Sequence.constant = function(value) {
    return Sequence.conj(value, __bind(function() {
      return this.constant(value);
    }, this));
  };
  make = function(seq) {
    var res;
    if (seq && (res = new Sequence(seq)) && !res.empty()) {
      return res;
    } else {
      return null;
    }
  };
  Sequence.prototype.S__ = Sequence;
  Sequence.memo = function(name, f) {
    this[name] = function(seq) {
      return f.call(this, make(seq));
    };
    this["" + name + "__"] = function(seq) {
      return f.call(this, seq);
    };
    return this.prototype[name] = function() {
      var x;
      x = f.call(this.S__, this);
      return (this[name] = function() {
        return x;
      })();
    };
  };
  Sequence.method = function(name, f) {
    this[name] = function() {
      var args, seq;
      seq = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return f.call.apply(f, [this, make(seq)].concat(__slice.call(args)));
    };
    this["" + name + "__"] = function() {
      var args, seq;
      seq = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return f.call.apply(f, [this, seq].concat(__slice.call(args)));
    };
    return this.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return f.call.apply(f, [this.S__, this].concat(__slice.call(args)));
    };
  };
  Sequence.operator = function(name, f) {
    this[name] = function() {
      var args, other, seq;
      seq = arguments[0], other = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return f.call.apply(f, [this, make(seq), make(other)].concat(__slice.call(args)));
    };
    this["" + name + "__"] = function() {
      var args, other, seq;
      seq = arguments[0], other = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return f.call.apply(f, [this, seq, other].concat(__slice.call(args)));
    };
    return this.prototype[name] = function() {
      var args, other;
      other = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return f.call.apply(f, [this.S__, this, make(other)].concat(__slice.call(args)));
    };
  };
  Sequence.method('empty', function(seq) {
    return !(seq != null) || typeof (seq.first()) === 'undefined';
  });
  Sequence.memo('size', function(seq) {
    var step;
    step = function(s, n) {
      if (s) {
        return recur(function() {
          return step(s.rest(), n + 1);
        });
      } else {
        return n;
      }
    };
    if (this.empty__(seq)) {
      return 0;
    } else {
      return resolve(step(seq, 0));
    }
  });
  Sequence.memo('last', function(seq) {
    var step;
    step = function(s) {
      if (s.rest()) {
        return recur(function() {
          return step(s.rest());
        });
      } else {
        return s.first();
      }
    };
    if (!this.empty__(seq)) {
      return resolve(step(seq));
    }
  });
  Sequence.method('take', function(seq, n) {
    if (this.empty__(seq) || n <= 0) {
      return null;
    } else {
      return Sequence.conj(seq.first(), __bind(function() {
        return this.take__(seq.rest(), n - 1);
      }, this));
    }
  });
  Sequence.method('takeWhile', function(seq, pred) {
    if (this.empty__(seq) || !pred(seq.first())) {
      return null;
    } else {
      return Sequence.conj(seq.first(), __bind(function() {
        return this.takeWhile__(seq.rest(), pred);
      }, this));
    }
  });
  Sequence.method('drop', function(seq, n) {
    var step;
    step = function(s, n) {
      if (s && n > 0) {
        return recur(function() {
          return step(s.rest(), n - 1);
        });
      } else {
        return s;
      }
    };
    if (this.empty__(seq)) {
      return null;
    } else {
      return resolve(step(seq, n));
    }
  });
  Sequence.method('dropWhile', function(seq, pred) {
    var step;
    step = function(s) {
      if (s && pred(s.first())) {
        return recur(function() {
          return step(s.rest());
        });
      } else {
        return s;
      }
    };
    if (this.empty__(seq)) {
      return null;
    } else {
      return resolve(step(seq));
    }
  });
  Sequence.method('get', __bind(function(seq, n) {
    var _ref4;
    if (n >= 0) {
      return (_ref4 = this.drop__(seq, n)) != null ? _ref4.first() : void 0;
    }
  }, Sequence));
  Sequence.method('select', function(seq, pred) {
    if (this.empty__(seq)) {
      return null;
    } else if (pred(seq.first())) {
      return Sequence.conj(seq.first(), __bind(function() {
        return this.select__(seq.rest(), pred);
      }, this));
    } else if (seq.rest()) {
      return this.select__(this.dropWhile__(seq.rest(), function(x) {
        return !pred(x);
      }), pred);
    } else {
      return null;
    }
  });
  Sequence.method('find', function(seq, pred) {
    var _ref4;
    return (_ref4 = this.select__(seq, pred)) != null ? _ref4.first() : void 0;
  });
  Sequence.method('forall', function(seq, pred) {
    return !this.select__(seq, function(x) {
      return !pred(x);
    });
  });
  Sequence.method('map', function(seq, func) {
    if (this.empty__(seq)) {
      return null;
    } else {
      return Sequence.conj(func(seq.first()), __bind(function() {
        return this.map__(seq.rest(), func);
      }, this));
    }
  });
  Sequence.method('accumulate', function(seq, start, op) {
    var first;
    if (this.empty__(seq)) {
      return null;
    } else {
      first = op(start, seq.first());
      return Sequence.conj(first, __bind(function() {
        return this.accumulate__(seq.rest(), first, op);
      }, this));
    }
  });
  Sequence.method('sums', function(seq) {
    return this.accumulate__(seq, 0, function(a, b) {
      return a + b;
    });
  });
  Sequence.method('products', function(seq) {
    return this.accumulate__(seq, 1, function(a, b) {
      return a * b;
    });
  });
  Sequence.method('reduce', function(seq, start, op) {
    if (this.empty__(seq)) {
      return start;
    } else {
      return this.accumulate__(seq, start, op).last();
    }
  });
  Sequence.method('sum', function(seq) {
    return this.reduce__(seq, 0, function(a, b) {
      return a + b;
    });
  });
  Sequence.method('product', function(seq) {
    return this.reduce__(seq, 1, function(a, b) {
      return a * b;
    });
  });
  Sequence.method('fold', function(seq, op) {
    return this.reduce__(seq.rest(), seq.first(), op);
  });
  Sequence.method('max', function(seq) {
    return this.fold__(seq, function(a, b) {
      if (b > a) {
        return b;
      } else {
        return a;
      }
    });
  });
  Sequence.method('min', function(seq) {
    return this.fold__(seq, function(a, b) {
      if (b < a) {
        return b;
      } else {
        return a;
      }
    });
  });
  Sequence.operator('combine', function(seq, other, op) {
    if (this.empty__(seq)) {
      return Sequence.map(other, function(a) {
        return op(null, a);
      });
    } else if (this.empty__(other)) {
      return Sequence.map(seq, function(a) {
        return op(a, null);
      });
    } else {
      return Sequence.conj(op(seq.first(), other.first()), __bind(function() {
        return this.combine__(seq.rest(), other.rest(), op);
      }, this));
    }
  });
  Sequence.operator('add', function(seq, other) {
    return this.combine__(seq, other, function(a, b) {
      return a + b;
    });
  });
  Sequence.operator('sub', function(seq, other) {
    return this.combine__(seq, other, function(a, b) {
      return a - b;
    });
  });
  Sequence.operator('mul', function(seq, other) {
    return this.combine__(seq, other, function(a, b) {
      return a * b;
    });
  });
  Sequence.operator('div', function(seq, other) {
    return this.combine__(seq, other, function(a, b) {
      return a / b;
    });
  });
  Sequence.operator('equals', function(seq, other) {
    return !(this.find__(this.combine__(seq, other, function(a, b) {
      return a === b;
    }), function(a) {
      return !a;
    }) != null);
  });
  Sequence.operator('interleave', function(seq, other) {
    if (this.empty__(seq)) {
      return other;
    } else {
      return Sequence.conj(seq.first(), __bind(function() {
        return this.interleave__(other, seq.rest());
      }, this));
    }
  });
  Sequence.operator('lazyConcat', function(seq, next) {
    if (seq) {
      return Sequence.conj(seq.first(), __bind(function() {
        return this.lazyConcat__(seq.rest(), next);
      }, this));
    } else {
      return next();
    }
  });
  Sequence.operator('concat', function(seq, other) {
    if (this.empty__(seq)) {
      return other;
    } else {
      return this.lazyConcat__(seq, function() {
        return other;
      });
    }
  });
  Sequence.method('flatten', function(seq) {
    if (this.empty__(seq)) {
      return null;
    } else if (seq.first()) {
      return this.lazyConcat__(make(seq.first()), __bind(function() {
        return this.flatten__(seq.rest());
      }, this));
    } else if (seq.rest()) {
      return this.flatten__(this.dropWhile__(seq.rest(), function(x) {
        var _ref4;
        return !((_ref4 = make(x)) != null ? _ref4.first() : void 0);
      }));
    } else {
      return null;
    }
  });
  Sequence.method('flatMap', function(seq, func) {
    return this.flatten__(this.map__(seq, func));
  });
  Sequence.operator('cartesian', function(seq, other) {
    return this.flatMap__(seq, __bind(function(a) {
      return this.map__(other, function(b) {
        return [a, b];
      });
    }, this));
  });
  Sequence.method('each', function(seq, func) {
    var step;
    step = function(s) {
      if (s) {
        func(s.first());
        return recur(function() {
          return step(s.rest());
        });
      }
    };
    if (!this.empty__(seq)) {
      return resolve(step(seq));
    }
  });
  Sequence.method('reverse', function(seq) {
    var step;
    step = __bind(function(r, s) {
      if (s) {
        return recur(__bind(function() {
          return step(Sequence.conj(s.first(), function() {
            return r;
          }), s.rest());
        }, this));
      } else {
        return r;
      }
    }, this);
    if (this.empty__(seq)) {
      return null;
    } else {
      return resolve(step(null, seq));
    }
  });
  Sequence.method('forced', function(seq) {
    if (this.empty__(seq)) {
      return null;
    } else {
      return Sequence.conj(seq.first(), (__bind(function() {
        return this.forced__(seq.rest());
      }, this)), 'forced');
    }
  });
  Sequence.method('into', function(seq, target) {
    var a, x;
    if (!(target != null)) {
      return this.reduce__(seq, null, function(s, item) {
        return Sequence.conj(item, function() {
          return s;
        });
      });
    } else if (typeof target.plus === 'function') {
      return this.reduce__(seq, target, function(s, item) {
        return s.plus(item);
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
      this.each__(seq, function(x) {
        return a.push(x);
      });
      return a;
    } else {
      throw new Error('cannot inject into #{target}');
    }
  });
  Sequence.method('join', function(seq, glue) {
    return this.into__(seq, []).join(glue);
  });
  Sequence.prototype.toString = function(limit) {
    var more, s, _ref4;
    if (limit == null) {
      limit = 10;
    }
    _ref4 = limit > 0 ? [this.take(limit), this.get(limit) != null] : [this, false], s = _ref4[0], more = _ref4[1];
    return '(' + Sequence.join(s, ', ') + (more ? ', ...)' : ')');
  };
  return Sequence;
}).call(this);
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref4 = this.pazy) != null ? _ref4 : this.pazy = {};
};
exports.Sequence = Sequence;
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  Sequence = require('sequence').Sequence;
} else {
  Sequence = this.pazy.Sequence;
}
util = {
  arrayWith: function(a, i, x) {
    var j, _ref5, _results;
    _results = [];
    for (j = 0, _ref5 = a.length; 0 <= _ref5 ? j < _ref5 : j > _ref5; 0 <= _ref5 ? j++ : j--) {
      _results.push((j === i ? x : a[j]));
    }
    return _results;
  },
  arrayWithInsertion: function(a, i, x) {
    var j, _ref5, _results;
    _results = [];
    for (j = 0, _ref5 = a.length; 0 <= _ref5 ? j <= _ref5 : j >= _ref5; 0 <= _ref5 ? j++ : j--) {
      _results.push((j < i ? a[j] : j > i ? a[j - 1] : x));
    }
    return _results;
  },
  arrayWithout: function(a, i) {
    var j, _ref5, _results;
    _results = [];
    for (j = 0, _ref5 = a.length; 0 <= _ref5 ? j < _ref5 : j > _ref5; 0 <= _ref5 ? j++ : j--) {
      if (j !== i) {
        _results.push(a[j]);
      }
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
    var _ref5;
    _ref5 = arguments.length === 0 ? [0, [], 0] : [bitmap, progeny, size], this.bitmap = _ref5[0], this.progeny = _ref5[1], this.size = _ref5[2];
    this.elements = Sequence.flatMap(this.progeny, function(n) {
      return n != null ? n.elements : void 0;
    });
  }
  BitmapIndexedNode.prototype.get = function(shift, key, data) {
    var bit, i, _ref5;
    _ref5 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref5[0], i = _ref5[1];
    if ((this.bitmap & bit) !== 0) {
      return this.progeny[i].get(shift + 5, key, data);
    }
  };
  BitmapIndexedNode.prototype.plus = function(shift, key, leaf) {
    var array, b, bit, i, m, n, newArray, node, progeny, v, _ref5;
    _ref5 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref5[0], i = _ref5[1];
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
            _results.push((this.bitmap & b) !== 0 ? this.progeny[util.indexForBit(this.bitmap, b)] : void 0);
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
    var bit, bits, i, newArray, newBitmap, newSize, node, v, _ref5;
    _ref5 = util.bitPosAndIndex(this.bitmap, key, shift), bit = _ref5[0], i = _ref5[1];
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
    if (prefix == null) {
      prefix = '';
    }
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
    if (prefix == null) {
      prefix = '';
    }
    return '.' + this.progeny.toString(prefix + ' ');
  };
  return ProxyNode;
})();
ArrayNode = (function() {
  function ArrayNode(progeny, i, node, size) {
    this.size = size;
    this.progeny = util.arrayWith(progeny, i, node);
    this.elements = Sequence.select(this.progeny, function(x) {
      return x;
    }).flatMap(function(n) {
      return n.elements;
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
        var _ref5, _results;
        _results = [];
        for (j = 1, _ref5 = this.progeny.length; 1 <= _ref5 ? j < _ref5 : j > _ref5; 1 <= _ref5 ? j++ : j--) {
          if (j !== i && this.progeny[j]) {
            _results.push(j);
          }
        }
        return _results;
      }).call(this);
      if (remaining.length <= 4) {
        bitmap = Sequence.reduce(remaining, 0, function(b, j) {
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
    if (prefix == null) {
      prefix = '';
    }
    pre = prefix + ' ';
    buf = (function() {
      var _i, _len, _ref5, _results;
      _ref5 = this.progeny;
      _results = [];
      for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
        x = _ref5[_i];
        if (x != null) {
          _results.push(x.toString(pre));
        }
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
    var _ref5, _ref6;
    this.root = root;
        if ((_ref5 = this.root) != null) {
      _ref5;
    } else {
      this.root = EmptyNode;
    };
    this.entries = (_ref6 = this.root) != null ? _ref6.elements : void 0;
  }
  Collection.prototype.size = function() {
    return this.root.size;
  };
  Collection.prototype.each = function(func) {
    var _ref5;
    if (func != null) {
      return (_ref5 = this.entries) != null ? _ref5.each(func) : void 0;
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
  Collection.prototype.plusAll = function(seq) {
    return this.update_(Sequence.reduce(seq, this.root, this.constructor.plusOne));
  };
  Collection.prototype.minus = function() {
    return this.minusAll(arguments);
  };
  Collection.prototype.minusAll = function(seq) {
    return this.update_(Sequence.reduce(seq, this.root, this.constructor.minusOne));
  };
  Collection.prototype.map = function(fun) {
    return new this.constructor().plusAll(Sequence.map(this.entries, fun));
  };
  Collection.prototype.toSeq = function() {
    return this.entries;
  };
  Collection.prototype.toArray = function() {
    return Sequence.into(this.entries, []);
  };
  Collection.prototype.toString = function() {
    return "" + this.constructor.name + "(" + this.root + ")";
  };
  return Collection;
})();
IntLeaf = (function() {
  function IntLeaf(key) {
    this.key = key;
    this.elements = Sequence.conj(this.key);
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
IntSet = (function() {
  __extends(IntSet, Collection);
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
})();
IntLeafWithValue = (function() {
  function IntLeafWithValue(key, value) {
    this.key = key;
    this.value = value;
    this.elements = Sequence.conj([this.key, this.value]);
  }
  IntLeafWithValue.prototype.size = 1;
  IntLeafWithValue.prototype.get = function(shift, key, data) {
    if (key === this.key) {
      return this.value;
    }
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
IntMap = (function() {
  __extends(IntMap, Collection);
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
})();
hashCode = function(obj) {
  if (!(obj != null)) {
    return 0;
  } else if (typeof obj.hashCode === "function" && util.isKey(obj.hashCode())) {
    return obj.hashCode();
  } else if (util.isKey(obj)) {
    return obj;
  } else if (typeof obj === 'string' && obj.length <= 1) {
    if (obj.length === 0) {
      return 1;
    } else {
      return obj.charCodeAt(0);
    }
  } else if (Sequence.accepts(obj)) {
    return Sequence.reduce(obj, 0, function(code, x) {
      return (code * 37 + hashCode(x)) & 0xffffffff;
    });
  } else if (typeof obj.toString === "function") {
    return hashCode(obj.toString());
  } else {
    try {
      return hashCode(String(obj));
    } catch (ex) {
      return hashCode(Object.prototype.toString.call(obj));
    }
  }
};
equalKeys = function(obj1, obj2) {
  if (typeof obj1 === 'string' || typeof obj2 === 'string') {
    return obj1 === obj2;
  } else if (Sequence.accepts(obj1) && Sequence.accepts(obj2)) {
    return !(Sequence.find(Sequence.combine(obj1, obj2, equalKeys), function(a) {
      return !a;
    }) != null);
  } else if ((obj1 != null) && typeof obj1.equals === "function") {
    return obj1.equals(obj2);
  } else if ((obj2 != null) && typeof obj2.equals === "function") {
    return obj2.equals(obj1);
  } else {
    return obj1 === obj2;
  }
};
CollisionNode = (function() {
  function CollisionNode(hash, bucket) {
    this.hash = hash;
    this.bucket = bucket;
    if (this.bucket == null) {
      this.bucket = [];
    }
    this.size = this.bucket.length;
    this.elements = Sequence.flatMap(this.bucket, function(n) {
      return n != null ? n.elements : void 0;
    });
  }
  CollisionNode.prototype.get = function(shift, hash, key) {
    var leaf;
    leaf = Sequence.find(this.bucket, function(v) {
      return equalKeys(v.key, key);
    });
    if (leaf != null) {
      return leaf.get(shift, hash, key);
    }
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
        return Sequence.find(this.bucket, function(v) {
          return !equalKeys(v.key, key);
        });
      default:
        return new CollisionNode(hash, this.bucketWithout(key));
    }
  };
  CollisionNode.prototype.toString = function() {
    return "" + (this.bucket.join("|"));
  };
  CollisionNode.prototype.bucketWithout = function(key) {
    var item, _i, _len, _ref5, _results;
    _ref5 = this.bucket;
    _results = [];
    for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
      item = _ref5[_i];
      if (!equalKeys(item.key, key)) {
        _results.push(item);
      }
    }
    return _results;
  };
  return CollisionNode;
})();
HashLeaf = (function() {
  function HashLeaf(hash, key) {
    this.hash = hash;
    this.key = key;
    this.elements = Sequence.conj(this.key);
  }
  HashLeaf.prototype.size = 1;
  HashLeaf.prototype.get = function(shift, hash, key) {
    if (equalKeys(key, this.key)) {
      return true;
    }
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
HashSet = (function() {
  __extends(HashSet, Collection);
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
})();
HashLeafWithValue = (function() {
  function HashLeafWithValue(hash, key, value) {
    this.hash = hash;
    this.key = key;
    this.value = value;
    this.elements = Sequence.conj([this.key, this.value]);
  }
  HashLeafWithValue.prototype.size = 1;
  HashLeafWithValue.prototype.get = function(shift, hash, key) {
    if (equalKeys(key, this.key)) {
      return this.value;
    }
  };
  HashLeafWithValue.prototype.plus = function(shift, hash, leaf) {
    var base;
    if (equalKeys(this.key, leaf.key)) {
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
HashMap = (function() {
  __extends(HashMap, Collection);
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
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref5 = this.pazy) != null ? _ref5 : this.pazy = {};
};
exports.IntSet = IntSet;
exports.IntMap = IntMap;
exports.HashMap = HashMap;
exports.HashSet = HashSet;
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  Sequence = require('sequence').Sequence;
  HashSet = require('indexed').HashSet;
} else {
  _ref6 = this.pazy, Sequence = _ref6.Sequence, HashSet = _ref6.HashSet;
}
Sequence.method('uniq', function(seq, seen) {
  var x;
  if (seen == null) {
    seen = new HashSet();
  }
  if (this.empty__(seq)) {
    return null;
  } else {
    x = seq.first();
    if (seen.contains(x)) {
      return this.uniq__(seq.rest(), seen);
    } else {
      return Sequence.conj(x, __bind(function() {
        return this.uniq__(seq.rest(), seen.plus(x));
      }, this));
    }
  }
});
if (typeof require !== 'undefined') {
  require.paths.unshift('#{__dirname}/../lib');
  Sequence = require('sequence').Sequence;
  _ref7 = require('functional'), recur = _ref7.recur, resolve = _ref7.resolve, suspend = _ref7.suspend;
} else {
  Sequence = pazy.Sequence, recur = pazy.recur, resolve = pazy.resolve, suspend = pazy.suspend;
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
    if (extensions == null) {
      extensions = DefaultExtensions;
    }
    this.build = function() {
      return Sequence.reduce(arguments, empty, function(s, a) {
        return s.plus(a);
      });
    };
    single = function(x) {
      var _ref8;
      if (x === Empty || (_ref8 = x.constructor, __indexOf.call(internal, _ref8) >= 0)) {
        return x.measure();
      } else {
        return measure.single(x);
      }
    };
    norm = function() {
      return Sequence.reduce(arguments, measure.empty, function(n, x) {
        if (x != null) {
          return measure.sum(n, single(x));
        } else {
          return n;
        }
      });
    };
    rev = function(x) {
      var _ref8;
      if ((_ref8 = x != null ? x.constructor : void 0) === Node2 || _ref8 === Node3) {
        return x.reverse();
      } else {
        return x;
      }
    };
    Instance = (function() {
      __extends(Instance, extensions);
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
        var l, r, x, _ref8;
        if (this.data !== Empty && p(norm(this.data))) {
          _ref8 = this.data.split(p, measure.empty), l = _ref8[0], x = _ref8[1], r = _ref8[2];
          return [new Instance(l), x, new Instance(r)];
        } else {
          return [this, void 0, new Instance(Empty)];
        }
      };
      Instance.prototype.takeUntil = function(p) {
        return this.split(p)[0];
      };
      Instance.prototype.dropUntil = function(p) {
        var l, r, x, _ref8;
        _ref8 = this.split(p), l = _ref8[0], x = _ref8[1], r = _ref8[2];
        if (x === void 0) {
          return r;
        } else {
          return new Instance(r.data.after(x));
        }
      };
      Instance.prototype.find = function(p) {
        return this.split(p)[1];
      };
      Instance.prototype.toString = function() {
        return this.data.reduceLeft("", function(s, x) {
          return s + ' ' + x;
        });
      };
      return Instance;
    })();
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
          return Sequence.conj(a, function() {
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
        var a, b, c, d, l, _ref8;
        if (this.l.constructor === Digit4) {
          _ref8 = this.l, a = _ref8.a, b = _ref8.b, c = _ref8.c, d = _ref8.d;
          l = new Digit2(x, a);
          return new Deep(l, suspend(__bind(function() {
            return this.m().after(new Node3(b, c, d));
          }, this)), this.r);
        } else {
          return new Deep(this.l.after(x), this.m, this.r);
        }
      };
      Deep.prototype.before = function(x) {
        var a, b, c, d, r, _ref8;
        if (this.r.constructor === Digit4) {
          _ref8 = this.r, a = _ref8.a, b = _ref8.b, c = _ref8.c, d = _ref8.d;
          r = new Digit2(d, x);
          return new Deep(this.l, suspend(__bind(function() {
            return this.m().before(new Node3(a, b, c));
          }, this)), r);
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
        if (l === Empty) {
          if (m() === Empty) {
            return asTree(r);
          } else {
            return new Deep(m().first().asDigit(), suspend(__bind(function() {
              return m().rest();
            }, this)), r);
          }
        } else {
          return new Deep(l, m, r);
        }
      };
      deepR = function(l, m, r) {
        if (r === Empty) {
          if (m() === Empty) {
            return asTree(l);
          } else {
            return new Deep(l, suspend(__bind(function() {
              return m().init();
            }, this)), m().last().asDigit());
          }
        } else {
          return new Deep(l, m, r);
        }
      };
      Deep.prototype.rest = function() {
        return deepL(this.l.rest(), suspend(__bind(function() {
          return this.m();
        }, this)), this.r);
      };
      Deep.prototype.init = function() {
        return deepR(this.l, suspend(__bind(function() {
          return this.m();
        }, this)), this.r.init());
      };
      nodes = function(n, s) {
        if (n === 0) {
          return null;
        } else if (n === 1 || n < 0) {
          throw new Error("this should not happen");
        } else if (n === 2 || n % 3 === 1) {
          return Sequence.conj((function(func, args, ctor) {
            ctor.prototype = func.prototype;
            var child = new ctor, result = func.apply(child, args);
            return typeof result === "object" ? result : child;
          })(Node2, s.take(2).into([]), function() {}), function() {
            return nodes(n - 2, s.drop(2));
          });
        } else {
          return Sequence.conj((function(func, args, ctor) {
            ctor.prototype = func.prototype;
            var child = new ctor, result = func.apply(child, args);
            return typeof result === "object" ? result : child;
          })(Node3, s.take(3).into([]), function() {}), function() {
            return nodes(n - 3, s.drop(3));
          });
        }
      };
      app3 = function(tLeft, list, tRight) {
        var s, tmp;
        if (tLeft === Empty) {
          return Sequence.reduce(Sequence.reverse(list), tRight, function(t, x) {
            return t.after(x);
          });
        } else if (tRight === Empty) {
          return Sequence.reduce(list, tLeft, function(t, x) {
            return t.before(x);
          });
        } else if (tLeft.constructor === Single) {
          return app3(Empty, list, tRight).after(tLeft.a);
        } else if (tRight.constructor === Single) {
          return app3(tLeft, list, Empty).before(tRight.a);
        } else {
          tmp = Sequence.flatten([asSeq(tLeft.r), list, asSeq(tRight.l)]);
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
        var i1, i2, l, ml, mr, r, x, xs, _ref10, _ref11, _ref8, _ref9;
        i1 = measure.sum(i, norm(this.l));
        if (p(i1)) {
          _ref8 = this.l.split(p, i), l = _ref8[0], x = _ref8[1], r = _ref8[2];
          return [
            asTree(l), x, deepL(r, suspend(__bind(function() {
              return this.m();
            }, this)), this.r)
          ];
        } else {
          i2 = measure.sum(i1, norm(this.m()));
          if (p(i2)) {
            _ref9 = this.m().split(p, i1), ml = _ref9[0], xs = _ref9[1], mr = _ref9[2];
            _ref10 = xs.asDigit().split(p, measure.sum(i1, norm(ml))), l = _ref10[0], x = _ref10[1], r = _ref10[2];
            return [
              deepR(this.l, (function() {
                return ml;
              }), l), x, deepL(r, (function() {
                return mr;
              }), this.r)
            ];
          } else {
            _ref11 = this.r.split(p, i2), l = _ref11[0], x = _ref11[1], r = _ref11[2];
            return [
              deepR(this.l, suspend(__bind(function() {
                return this.m();
              }, this)), l), x, asTree(r)
            ];
          }
        }
      };
      Deep.prototype.reverse = function() {
        return new Deep(this.r.reverse(), suspend(__bind(function() {
          return this.m().reverse();
        }, this)), this.l.reverse());
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
CountedExtensions = (function() {
  __extends(CountedExtensions, DefaultExtensions);
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
    var l, r, x, _ref8;
    _ref8 = this.split(function(m) {
      return m > i;
    }), l = _ref8[0], x = _ref8[1], r = _ref8[2];
    return [l, r.after(x)];
  };
  return CountedExtensions;
})();
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
  return (function() {
    var after, before, concat, intersect, merge;
    __extends(_Class, extensions);
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
      var l, r, x, _ref8;
      _ref8 = this.split(function(m) {
        return !less(m, k);
      }), l = _ref8[0], x = _ref8[1], r = _ref8[2];
      return [l, after(r, x)];
    };
    _Class.prototype.insert = function(k) {
      var l, r, _ref8;
      _ref8 = this.partition(k), l = _ref8[0], r = _ref8[1];
      return concat(l, after(r, k));
    };
    _Class.prototype.deleteAll = function(k) {
      var l, r, _ref8;
      _ref8 = this.partition(k), l = _ref8[0], r = _ref8[1];
      return concat(l, r.dropUntil(function(m) {
        return less(k, m);
      }));
    };
    merge = function(s, t1, t2) {
      var k, l, r, x, _ref8;
      if (t2.isEmpty()) {
        return concat(s, t1);
      } else {
        k = t2.first();
        _ref8 = t1.split(function(m) {
          return less(k, m);
        }), l = _ref8[0], x = _ref8[1], r = _ref8[2];
        return recur(function() {
          var a;
          a = concat(s, before(l, k));
          return merge(a, t2.rest(), after(r, x));
        });
      }
    };
    _Class.prototype.merge = function(other) {
      return resolve(merge(this.empty(), this, other));
    };
    intersect = function(s, t1, t2) {
      var k, l, r, x, _ref8;
      if (t2.isEmpty()) {
        return s;
      } else {
        k = t2.first();
        _ref8 = t1.split(function(m) {
          return !less(m, k);
        }), l = _ref8[0], x = _ref8[1], r = _ref8[2];
        if (less(k, x)) {
          return recur(function() {
            return intersect(s, t2.rest(), after(r, x));
          });
        } else {
          return recur(function() {
            return intersect(before(s, x), t2.rest(), r);
          });
        }
      }
    };
    _Class.prototype.intersect = function(other) {
      return resolve(intersect(this.empty(), this, other));
    };
    _Class.prototype.plus = _Class.prototype.insert;
    return _Class;
  })();
};
SortedSeqType = (function() {
  __extends(SortedSeqType, FingerTreeType);
  function SortedSeqType(less, extensions) {
    if (less == null) {
      less = (function(a, b) {
        return a < b;
      });
    }
    if (extensions == null) {
      extensions = Void;
    }
    SortedSeqType.__super__.constructor.call(this, OrderMeasure, SortedExtensions(less, extensions));
  }
  return SortedSeqType;
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref8 = this.pazy) != null ? _ref8 : this.pazy = {};
};
exports.FingerTreeType = FingerTreeType;
exports.CountedSeq = CountedSeq;
exports.SortedSeqType = SortedSeqType;
exports.SortedSeq = new SortedSeqType();
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  _ref9 = require('functional'), recur = _ref9.recur, resolve = _ref9.resolve;
  HashMap = require('indexed').HashMap;
} else {
  _ref10 = this.pazy, recur = _ref10.recur, resolve = _ref10.resolve, HashMap = _ref10.HashMap;
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
    var flatten, root, seek;
    if (!(this.parent.get(x) != null)) {
      this.parent = this.parent.plus([x, x]);
      this.rank = this.rank.plus([x, 0]);
      return x;
    } else {
      seek = __bind(function(y) {
        var z;
        z = this.parent.get(y);
        if (z === y) {
          return z;
        } else {
          return recur(function() {
            return seek(z);
          });
        }
      }, this);
      root = resolve(seek(x));
      flatten = __bind(function(y) {
        var z;
        z = this.parent.get(y);
        this.parent = this.parent.plus([y, root]);
        if (z !== y) {
          return recur(function() {
            return flatten(z);
          });
        }
      }, this);
      resolve(flatten(x));
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
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref11 = this.pazy) != null ? _ref11 : this.pazy = {};
};
exports.Partition = Partition;
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  Sequence = require('sequence').Sequence;
} else {
  Sequence = this.pazy.Sequence;
}
Stack = (function() {
  function Stack(s) {
    this.seq = s;
  }
  Stack.prototype.push = function(x) {
    return new Stack(Sequence.conj(x, __bind(function() {
      return this.seq;
    }, this)));
  };
  Stack.prototype.first = function() {
    var _ref12;
    return (_ref12 = this.seq) != null ? _ref12.first() : void 0;
  };
  Stack.prototype.rest = function() {
    if (this.seq) {
      return new Stack(this.seq.rest());
    }
  };
  return Stack;
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref12 = this.pazy) != null ? _ref12 : this.pazy = {};
};
exports.Stack = Stack;
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  Sequence = require('sequence').Sequence;
} else {
  Sequence = this.pazy.Sequence;
}
Queue = (function() {
  var rotate;
  function Queue(f, r, s) {
    var _ref13;
    if (s) {
      _ref13 = [f, r, s.rest()], this.front = _ref13[0], this.rear = _ref13[1], this.schedule = _ref13[2];
    } else if (f || r) {
      this.front = this.schedule = rotate(f, r, null);
      this.rear = null;
    } else {
      this.front = this.rear = this.schedule = null;
    }
  }
  rotate = function(f, r, a) {
    var a1;
    a1 = Sequence.conj(r.first(), (function() {
      return a;
    }));
    if (f) {
      return Sequence.conj(f.first(), (function() {
        return rotate(f.rest(), r.rest(), a1);
      }));
    } else {
      return a1;
    }
  };
  Queue.prototype.push = function(x) {
    return new Queue(this.front, Sequence.conj(x, (__bind(function() {
      return this.rear;
    }, this))), this.schedule);
  };
  Queue.prototype.first = function() {
    var _ref13;
    return (_ref13 = this.front) != null ? _ref13.first() : void 0;
  };
  Queue.prototype.rest = function() {
    if (this.front) {
      return new Queue(this.front.rest(), this.rear, this.schedule);
    }
  };
  return Queue;
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref13 = this.pazy) != null ? _ref13 : this.pazy = {};
};
exports.Queue = Queue;
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  _ref14 = require('functional'), recur = _ref14.recur, resolve = _ref14.resolve;
  Sequence = require('sequence').Sequence;
} else {
  _ref15 = this.pazy, recur = _ref15.recur, resolve = _ref15.resolve, Sequence = _ref15.Sequence;
}
quicktest = (typeof process !== "undefined" && process !== null ? process.argv[2] : void 0) === '--test';
rdump = function(s) {
  return "" + (s ? s.into([]).join('|') : '[]');
};
dump = function(s) {
  return rdump(s != null ? s.reverse() : void 0);
};
if (quicktest) {
  _ref16 = [10000, 100], BASE = _ref16[0], HALFBASE = _ref16[1];
  log = function(str) {
    return console.log(str);
  };
} else {
  log = function(str) {};
  _ref17 = Sequence.from(1).map(function(n) {
    return [Math.pow(10, 2 * n), Math.pow(10, n)];
  }).takeWhile(function(_arg) {
    var b, h;
    b = _arg[0], h = _arg[1];
    return 2 * b - 2 !== 2 * b - 1;
  }).last(), BASE = _ref17[0], HALFBASE = _ref17[1];
}
ZERO = Sequence.conj(0);
ONE = Sequence.conj(1);
TWO = Sequence.conj(2);
cleanup = function(s) {
  var _ref18, _ref19;
  return (s != null ? (_ref18 = s.reverse()) != null ? (_ref19 = _ref18.dropWhile(function(x) {
    return x === 0;
  })) != null ? _ref19.reverse() : void 0 : void 0 : void 0) || null;
};
cmp = function(r, s) {
  var d, _ref18, _ref19;
  d = Sequence.combine(r, s, function(a, b) {
    return a - b;
  });
  return (d != null ? (_ref18 = d.reverse()) != null ? (_ref19 = _ref18.dropWhile(function(x) {
    return x === 0;
  })) != null ? _ref19.first() : void 0 : void 0 : void 0) || 0;
};
add = function(r, s, c) {
  var carry, digit, r_, s_, x, _ref18, _ref19;
  if (c == null) {
    c = 0;
  }
  if (c || (r && s)) {
    _ref18 = [r || ZERO, s || ZERO], r_ = _ref18[0], s_ = _ref18[1];
    x = r_.first() + s_.first() + c;
    _ref19 = x >= BASE ? [x - BASE, 1] : [x, 0], digit = _ref19[0], carry = _ref19[1];
    return Sequence.conj(digit, function() {
      return add(r_.rest(), s_.rest(), carry);
    });
  } else {
    return s || r;
  }
};
sub = function(r, s) {
  var step;
  step = function(r, s, b) {
    var borrow, digit, r_, s_, x, _ref18, _ref19;
    if (b == null) {
      b = 0;
    }
    if (b || (r && s)) {
      _ref18 = [r || ZERO, s || ZERO], r_ = _ref18[0], s_ = _ref18[1];
      x = r_.first() - s_.first() - b;
      _ref19 = x < 0 ? [x + BASE, 1] : [x, 0], digit = _ref19[0], borrow = _ref19[1];
      return Sequence.conj(digit, function() {
        return step(r_.rest(), s_.rest(), borrow);
      });
    } else {
      return s || r;
    }
  };
  return cleanup(step(r, s));
};
split = function(n) {
  return [n % HALFBASE, Math.floor(n / HALFBASE)];
};
digitTimesDigit = function(a, b) {
  var a0, a1, b0, b1, carry, lo, m0, m1, tmp, _ref18, _ref19, _ref20, _ref21;
  if (b < BASE / a) {
    return [a * b, 0];
  } else {
    _ref18 = split(a), a0 = _ref18[0], a1 = _ref18[1];
    _ref19 = split(b), b0 = _ref19[0], b1 = _ref19[1];
    _ref20 = split(a0 * b1 + b0 * a1), m0 = _ref20[0], m1 = _ref20[1];
    tmp = a0 * b0 + m0 * HALFBASE;
    _ref21 = tmp < BASE ? [tmp, 0] : [tmp - BASE, 1], lo = _ref21[0], carry = _ref21[1];
    return [lo, a1 * b1 + m1 + carry];
  }
};
seqTimesDigit = function(s, d, c) {
  var hi, lo, s_, _ref18;
  if (c == null) {
    c = 0;
  }
  if (c || s) {
    s_ = s || ZERO;
    _ref18 = digitTimesDigit(d, s_.first()), lo = _ref18[0], hi = _ref18[1];
    return Sequence.conj(lo + c, function() {
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
      return Sequence.conj(t.first(), function() {
        return step(t.rest(), a.rest(), b);
      });
    } else {
      return r;
    }
  };
  return step(null, a, b);
};
divmod = function(r, s) {
  var d, m, r_, s_, scale, step, x, _ref18, _ref19;
  scale = Math.floor(BASE / (s.last() + 1));
  _ref18 = (function() {
    var _i, _len, _ref18, _results;
    _ref18 = [r, s];
    _results = [];
    for (_i = 0, _len = _ref18.length; _i < _len; _i++) {
      x = _ref18[_i];
      _results.push(new Sequence(seqTimesDigit(x, scale)));
    }
    return _results;
  })(), r_ = _ref18[0], s_ = _ref18[1];
  _ref19 = [s_.size(), s_.last() + 1], m = _ref19[0], d = _ref19[1];
  step = function(q, h, t) {
    var f, n;
    f = (h != null ? h.size() : void 0) < m ? 0 : (n = ((h != null ? h.last() : void 0) * ((h != null ? h.size() : void 0) > m ? BASE : 1)) || 0, (Math.floor(n / d)) || (cmp(h, s_) >= 0 ? 1 : 0));
    if (f) {
      return recur(function() {
        return step(add(q, Sequence.conj(f)), sub(h, seqTimesDigit(s_, f)), t);
      });
    } else if (t) {
      return recur(function() {
        return step(Sequence.conj(0, function() {
          return q;
        }), Sequence.conj(t.first(), function() {
          return h;
        }), t.rest());
      });
    } else {
      return [cleanup(q), h && div(h, Sequence.conj(scale))];
    }
  };
  return resolve(step(null, null, r_.reverse()));
};
div = function(r, s) {
  return divmod(r, s)[0];
};
mod = function(r, s) {
  return divmod(r, s)[1];
};
pow = function(r, s) {
  var step;
  step = function(p, r, s) {
    if (s) {
      if (s.first() % 2 === 1) {
        return recur(function() {
          return step(mul(p, r), r, sub(s, ONE));
        });
      } else {
        return recur(function() {
          return step(p, new Sequence(mul(r, r)), div(s, TWO));
        });
      }
    } else {
      return p;
    }
  };
  return resolve(step(ONE, r, s));
};
sqrt = function(s) {
  var n, step;
  n = s.size();
  if (n === 1) {
    return Sequence.conj(Math.floor(Math.sqrt(s.first())));
  } else {
    step = function(r) {
      var rn;
      rn = new Sequence(div(add(r, div(s, r)), TWO));
      if (cmp(r, rn)) {
        return recur(function() {
          return step(rn);
        });
      } else {
        return rn;
      }
    };
    return resolve(step(s.take(n >> 1)));
  }
};
LongInt = (function() {
  var create;
  LongInt.base = function() {
    return BASE;
  };
  function LongInt(n) {
    var m, make_digits, _ref18;
    if (n == null) {
      n = 0;
    }
    make_digits = function(m) {
      if (m) {
        return Sequence.conj(m % BASE, function() {
          return make_digits(Math.floor(m / BASE));
        });
      }
    };
    _ref18 = n < 0 ? [-n, -1] : [n, 1], m = _ref18[0], this.sign__ = _ref18[1];
    this.digits__ = cleanup(new Sequence(make_digits(m)));
  }
  create = function(digits, sign) {
    var n;
    n = new LongInt();
    n.digits__ = cleanup(new Sequence(digits));
    n.sign__ = n.digits__ != null ? sign : 1;
    return n;
  };
  LongInt.make = function(x) {
    if (x instanceof LongInt) {
      return x;
    } else if (typeof x === 'number') {
      return new LongInt(x);
    } else {
      throw new Error("" + x + " is not a number");
    }
  };
  LongInt.prototype.toString = function() {
    var buf, rev, zeroes, _ref18, _ref19, _ref20;
    zeroes = BASE.toString().slice(1);
    rev = (_ref18 = this.digits__) != null ? (_ref19 = _ref18.reverse()) != null ? _ref19.dropWhile(function(d) {
      return d === 0;
    }) : void 0 : void 0;
    buf = [rev != null ? rev.first().toString() : void 0];
    if (rev != null) {
      if ((_ref20 = rev.rest()) != null) {
        _ref20.each(function(d) {
          var t;
          t = d.toString();
          return buf.push("" + zeroes.slice(t.length) + t);
        });
      }
    }
    if (rev) {
      if (this.sign() < 0) {
        buf.unshift('-');
      }
    } else {
      buf.push('0');
    }
    return buf.join('');
  };
  LongInt.prototype.toNumber = function() {
    var rev, step, _ref18, _ref19;
    step = function(n, s) {
      if (s) {
        return recur(function() {
          return step(n * BASE + s.first(), s.rest());
        });
      } else {
        return n;
      }
    };
    rev = (_ref18 = this.digits__) != null ? (_ref19 = _ref18.reverse()) != null ? _ref19.dropWhile(function(d) {
      return d === 0;
    }) : void 0 : void 0;
    return this.sign() * resolve(step(0, rev));
  };
  LongInt.operator = function(names, arity, code) {
    var f, name, _i, _len;
    f = function() {
      var args, x;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return code.apply(this, (function() {
        var _i, _len, _ref18, _results;
        _ref18 = args.slice(0, arity - 1);
        _results = [];
        for (_i = 0, _len = _ref18.length; _i < _len; _i++) {
          x = _ref18[_i];
          _results.push(LongInt.make(x));
        }
        return _results;
      })());
    };
    for (_i = 0, _len = names.length; _i < _len; _i++) {
      name = names[_i];
      this.prototype[name] = f;
    }
    return null;
  };
  LongInt.operator(['neg', '-'], 1, function() {
    return create(this.digits__, -this.sign());
  });
  LongInt.operator(['abs'], 1, function() {
    return create(this.digits__, 1);
  });
  LongInt.operator(['sign'], 1, function() {
    return this.sign__;
  });
  LongInt.operator(['cmp', '<=>'], 2, function(other) {
    if (this.sign() !== other.sign()) {
      return this.sign();
    } else {
      return this.sign() * cmp(this.digits__, other.digits__);
    }
  });
  LongInt.operator(['plus', '+'], 2, function(other) {
    if (this.sign() !== other.sign()) {
      return this.minus(other.neg());
    } else {
      return create(add(this.digits__, other.digits__), this.sign());
    }
  });
  LongInt.operator(['minus', '-'], 2, function(other) {
    if (this.sign() !== other.sign()) {
      return this.plus(other.neg());
    } else if (this.abs().cmp(other.abs()) < 0) {
      return create(sub(other.digits__, this.digits__), -this.sign());
    } else {
      return create(sub(this.digits__, other.digits__), this.sign());
    }
  });
  LongInt.operator(['times', '*'], 2, function(other) {
    return create(mul(this.digits__, other.digits__), this.sign() * other.sign());
  });
  LongInt.operator(['div', '/'], 2, function(other) {
    var d;
    d = this.abs().cmp(other.abs());
    if (d < 0) {
      return new LongInt(0);
    } else if (d === 0) {
      return new LongInt(this.sign() * other.sign());
    } else {
      return create(div(this.digits__, other.digits__), this.sign() * other.sign());
    }
  });
  LongInt.operator(['mod', '%'], 2, function(other) {
    var d;
    d = this.abs().cmp(other.abs());
    if (d < 0) {
      return this;
    } else if (d === 0) {
      return new LongInt(0);
    } else {
      return create(mod(this.digits__, other.digits__), this.sign() * other.sign());
    }
  });
  LongInt.operator(['pow', '**'], 2, function(other) {
    if (other.sign() > 0) {
      return create(pow(this.digits__, other.digits__), this.sign());
    } else {
      throw new Error('exponent must not be negative');
    }
  });
  LongInt.operator(['sqrt'], 1, function() {
    if (this.sign() > 0) {
      return create(sqrt(this.digits__));
    } else {
      throw new Error('number must not be negative');
    }
  });
  LongInt.operator(['gcd'], 2, function(other) {
    var a, b, step, _ref18;
    step = function(a, b) {
      if (b.cmp(0) > 0) {
        return recur(function() {
          return step(b, a.mod(b));
        });
      } else {
        return a;
      }
    };
    _ref18 = [this.abs(), other.abs()], a = _ref18[0], b = _ref18[1];
    if (a.cmp(b) > 0) {
      return resolve(step(a, b));
    } else {
      return resolve(step(b, a));
    }
  });
  return LongInt;
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref18 = this.pazy) != null ? _ref18 : this.pazy = {};
};
exports.LongInt = LongInt;
if (quicktest) {
  a = new LongInt(9950);
  a2 = a['*'](a);
  a3 = a2['*'](a);
  log("(" + a + "**3 + 1) / " + a + "**2 = " + (a3.plus(1).div(a2)) + " (" + (a3.plus(1).mod(a2)) + ")");
  log("");
  log("(" + a + "**3 - 1) / " + a + "**2 = " + (a3.minus(1).div(a2)) + " (" + (a3.minus(1).mod(a2)) + ")");
  log("");
  b = new LongInt(111111112);
  log("" + b + " / 37 = " + (b.div(37)) + " (" + (b.mod(37)) + ")");
  log("");
  c = new LongInt((2 << 26) * 29 * 31);
  d = new LongInt(3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31);
  log("" + c + " gcd " + d + " = " + (c.gcd(d)) + " (expected " + (29 * 31) + ")");
  log("");
}
if (typeof require !== 'undefined') {
  require.paths.unshift(__dirname);
  LongInt = require('long_int').LongInt;
} else {
  LongInt = this.pazy.LongInt;
}
Rational = (function() {
  var convert;
  function Rational(num, den, quick) {
    var n, sgn, _ref19, _ref20;
    if (num == null) {
      num = 0;
    }
    if (den == null) {
      den = 1;
    }
    if (quick == null) {
      quick = false;
    }
    sgn = LongInt.make(den).cmp(0);
    if (sgn === 0) {
      throw new Error("denominator is zero");
    } else if (sgn < 0) {
      _ref19 = [LongInt.make(num).neg(), LongInt.make(den).neg()], n = _ref19[0], d = _ref19[1];
    } else {
      _ref20 = [LongInt.make(num), LongInt.make(den)], n = _ref20[0], d = _ref20[1];
    }
    if (quick) {
      this.num__ = n;
      this.den__ = d;
    } else {
      a = n.gcd(d);
      this.num__ = n.div(a);
      this.den__ = d.div(a);
    }
  }
  Rational.prototype.numerator = function() {
    return this.num__;
  };
  Rational.prototype.denominator = function() {
    return this.den__;
  };
  convert = function(x) {
    if (x instanceof Rational) {
      return x;
    } else if (x instanceof LongInt) {
      return new Rational(x);
    } else if (typeof x === 'number') {
      return new Rational(x);
    } else {
      throw new Error("" + x + " is not a number");
    }
  };
  Rational.prototype.toString = function() {
    if (this.den__.cmp(1) === 0) {
      return this.num__.toString();
    } else {
      return "" + (this.num__.toString()) + "/" + (this.den__.toString());
    }
  };
  Rational.operator = function(names, arity, code) {
    var f, name, _i, _len;
    f = function() {
      var args, x;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return code.apply(this, (function() {
        var _i, _len, _ref19, _results;
        _ref19 = args.slice(0, arity - 1);
        _results = [];
        for (_i = 0, _len = _ref19.length; _i < _len; _i++) {
          x = _ref19[_i];
          _results.push(convert(x));
        }
        return _results;
      })());
    };
    for (_i = 0, _len = names.length; _i < _len; _i++) {
      name = names[_i];
      this.prototype[name] = f;
    }
    return null;
  };
  Rational.operator(['neg', '-'], 1, function() {
    return new Rational(this.num__.neg(), this.den__, true);
  });
  Rational.operator(['inv'], 1, function() {
    return new Rational(this.den__, this.num__, true);
  });
  Rational.operator(['abs'], 1, function() {
    return new Rational(this.num__.abs(), this.den__, true);
  });
  Rational.operator(['sign'], 1, function() {
    return this.num__.sign();
  });
  Rational.operator(['plus', '+'], 2, function(other) {
    var n, t;
    a = this.den__.gcd(other.den__);
    t = this.den__.div(a);
    n = other.den__.div(a).times(this.num__).plus(t.times(other.num__));
    return new Rational(n, t.times(other.den__));
  });
  Rational.operator(['minus', '-'], 2, function(other) {
    return this.plus(other.neg());
  });
  Rational.operator(['cmp', '<=>'], 2, function(other) {
    return this.minus(other).num__.cmp(0);
  });
  Rational.operator(['times', '*'], 2, function(other) {
    var n;
    a = this.num__.gcd(other.den__);
    b = this.den__.gcd(other.num__);
    n = this.num__.div(a).times(other.num__.div(b));
    d = this.den__.div(b).times(other.den__.div(a));
    return new Rational(n, d, true);
  });
  Rational.operator(['div', '/'], 2, function(other) {
    return this.times(other.inv());
  });
  Rational.operator(['pow', '**'], 2, function(other) {
    if (other.den__.cmp(1) !== 0) {
      throw new Error('exponent must be an integer');
    }
    return new Rational(this.num__.pow(other.num__), this.den__.pow(other.num__));
  });
  return Rational;
})();
if (typeof exports !== "undefined" && exports !== null) {
  exports;
} else {
  exports = (_ref19 = this.pazy) != null ? _ref19 : this.pazy = {};
};
exports.Rational = Rational;