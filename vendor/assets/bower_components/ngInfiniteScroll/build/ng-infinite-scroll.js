/* ng-infinite-scroll - v1.3.0 - 2016-11-04 */
(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define(['module', 'exports', 'angular'], factory);
  } else if (typeof exports !== "undefined") {
    factory(module, exports, require('angular'));
  } else {
    var mod = {
      exports: {}
    };
    factory(mod, mod.exports, global.angular);
    global.infiniteScroll = mod.exports;
  }
})(this, function (module, exports, _angular) {
  'use strict';

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  var _angular2 = _interopRequireDefault(_angular);

  function _interopRequireDefault(obj) {
    return obj && obj.__esModule ? obj : {
      default: obj
    };
  }

  var MODULE_NAME = 'infinite-scroll';

  _angular2['default'].module(MODULE_NAME, []).value('THROTTLE_MILLISECONDS', null).directive('infiniteScroll', ['$rootScope', '$window', '$interval', 'THROTTLE_MILLISECONDS', function ($rootScope, $window, $interval, THROTTLE_MILLISECONDS) {
    return {
      scope: {
        infiniteScroll: '&',
        infiniteScrollContainer: '=',
        infiniteScrollDistance: '=',
        infiniteScrollDisabled: '=',
        infiniteScrollUseDocumentBottom: '=',
        infiniteScrollListenForEvent: '@'
      },

      link: function link(scope, elem, attrs) {
        var windowElement = _angular2['default'].element($window);

        var scrollDistance = null;
        var scrollEnabled = null;
        var checkWhenEnabled = null;
        var container = null;
        var immediateCheck = true;
        var useDocumentBottom = false;
        var unregisterEventListener = null;
        var checkInterval = false;

        function height(element) {
          var el = element[0] || element;

          if (isNaN(el.offsetHeight)) {
            return el.document.documentElement.clientHeight;
          }
          return el.offsetHeight;
        }

        function pageYOffset(element) {
          var el = element[0] || element;

          if (isNaN(window.pageYOffset)) {
            return el.document.documentElement.scrollTop;
          }
          return el.ownerDocument.defaultView.pageYOffset;
        }

        function offsetTop(element) {
          if (!(!element[0].getBoundingClientRect || element.css('none'))) {
            return element[0].getBoundingClientRect().top + pageYOffset(element);
          }
          return undefined;
        }

        // infinite-scroll specifies a function to call when the window,
        // or some other container specified by infinite-scroll-container,
        // is scrolled within a certain range from the bottom of the
        // document. It is recommended to use infinite-scroll-disabled
        // with a boolean that is set to true when the function is
        // called in order to throttle the function call.
        function defaultHandler() {
          var containerBottom = void 0;
          var elementBottom = void 0;
          if (container === windowElement) {
            containerBottom = height(container) + pageYOffset(container[0].document.documentElement);
            elementBottom = offsetTop(elem) + height(elem);
          } else {
            containerBottom = height(container);
            var containerTopOffset = 0;
            if (offsetTop(container) !== undefined) {
              containerTopOffset = offsetTop(container);
            }
            elementBottom = offsetTop(elem) - containerTopOffset + height(elem);
          }

          if (useDocumentBottom) {
            elementBottom = height((elem[0].ownerDocument || elem[0].document).documentElement);
          }

          var remaining = elementBottom - containerBottom;
          var shouldScroll = remaining <= height(container) * scrollDistance + 1;

          if (shouldScroll) {
            checkWhenEnabled = true;

            if (scrollEnabled) {
              if (scope.$$phase || $rootScope.$$phase) {
                scope.infiniteScroll();
              } else {
                scope.$apply(scope.infiniteScroll);
              }
            }
          } else {
            if (checkInterval) {
              $interval.cancel(checkInterval);
            }
            checkWhenEnabled = false;
          }
        }

        // The optional THROTTLE_MILLISECONDS configuration value specifies
        // a minimum time that should elapse between each call to the
        // handler. N.b. the first call the handler will be run
        // immediately, and the final call will always result in the
        // handler being called after the `wait` period elapses.
        // A slimmed down version of underscore's implementation.
        function throttle(func, wait) {
          var timeout = null;
          var previous = 0;

          function later() {
            previous = new Date().getTime();
            $interval.cancel(timeout);
            timeout = null;
            return func.call();
          }

          function throttled() {
            var now = new Date().getTime();
            var remaining = wait - (now - previous);
            if (remaining <= 0) {
              $interval.cancel(timeout);
              timeout = null;
              previous = now;
              func.call();
            } else if (!timeout) {
              timeout = $interval(later, remaining, 1);
            }
          }

          return throttled;
        }

        var handler = THROTTLE_MILLISECONDS != null ? throttle(defaultHandler, THROTTLE_MILLISECONDS) : defaultHandler;

        function handleDestroy() {
          container.unbind('scroll', handler);
          if (unregisterEventListener != null) {
            unregisterEventListener();
            unregisterEventListener = null;
          }
          if (checkInterval) {
            $interval.cancel(checkInterval);
          }
        }

        scope.$on('$destroy', handleDestroy);

        // infinite-scroll-distance specifies how close to the bottom of the page
        // the window is allowed to be before we trigger a new scroll. The value
        // provided is multiplied by the container height; for example, to load
        // more when the bottom of the page is less than 3 container heights away,
        // specify a value of 3. Defaults to 0.
        function handleInfiniteScrollDistance(v) {
          scrollDistance = parseFloat(v) || 0;
        }

        scope.$watch('infiniteScrollDistance', handleInfiniteScrollDistance);
        // If I don't explicitly call the handler here, tests fail. Don't know why yet.
        handleInfiniteScrollDistance(scope.infiniteScrollDistance);

        // infinite-scroll-disabled specifies a boolean that will keep the
        // infnite scroll function from being called; this is useful for
        // debouncing or throttling the function call. If an infinite
        // scroll is triggered but this value evaluates to true, then
        // once it switches back to false the infinite scroll function
        // will be triggered again.
        function handleInfiniteScrollDisabled(v) {
          scrollEnabled = !v;
          if (scrollEnabled && checkWhenEnabled) {
            checkWhenEnabled = false;
            handler();
          }
        }

        scope.$watch('infiniteScrollDisabled', handleInfiniteScrollDisabled);
        // If I don't explicitly call the handler here, tests fail. Don't know why yet.
        handleInfiniteScrollDisabled(scope.infiniteScrollDisabled);

        // use the bottom of the document instead of the element's bottom.
        // This useful when the element does not have a height due to its
        // children being absolute positioned.
        function handleInfiniteScrollUseDocumentBottom(v) {
          useDocumentBottom = v;
        }

        scope.$watch('infiniteScrollUseDocumentBottom', handleInfiniteScrollUseDocumentBottom);
        handleInfiniteScrollUseDocumentBottom(scope.infiniteScrollUseDocumentBottom);

        // infinite-scroll-container sets the container which we want to be
        // infinte scrolled, instead of the whole window. Must be an
        // Angular or jQuery element, or, if jQuery is loaded,
        // a jQuery selector as a string.
        function changeContainer(newContainer) {
          if (container != null) {
            container.unbind('scroll', handler);
          }

          container = newContainer;
          if (newContainer != null) {
            container.bind('scroll', handler);
          }
        }

        changeContainer(windowElement);

        if (scope.infiniteScrollListenForEvent) {
          unregisterEventListener = $rootScope.$on(scope.infiniteScrollListenForEvent, handler);
        }

        function handleInfiniteScrollContainer(newContainer) {
          // TODO: For some reason newContainer is sometimes null instead
          // of the empty array, which Angular is supposed to pass when the
          // element is not defined
          // (https://github.com/sroze/ngInfiniteScroll/pull/7#commitcomment-5748431).
          // So I leave both checks.
          if (!(newContainer != null) || newContainer.length === 0) {
            return;
          }

          var newerContainer = void 0;

          if (newContainer.nodeType && newContainer.nodeType === 1) {
            newerContainer = _angular2['default'].element(newContainer);
          } else if (typeof newContainer.append === 'function') {
            newerContainer = _angular2['default'].element(newContainer[newContainer.length - 1]);
          } else if (typeof newContainer === 'string') {
            newerContainer = _angular2['default'].element(document.querySelector(newContainer));
          } else {
            newerContainer = newContainer;
          }

          if (newerContainer == null) {
            throw new Error('invalid infinite-scroll-container attribute.');
          }
          changeContainer(newerContainer);
        }

        scope.$watch('infiniteScrollContainer', handleInfiniteScrollContainer);
        handleInfiniteScrollContainer(scope.infiniteScrollContainer || []);

        // infinite-scroll-parent establishes this element's parent as the
        // container infinitely scrolled instead of the whole window.
        if (attrs.infiniteScrollParent != null) {
          changeContainer(_angular2['default'].element(elem.parent()));
        }

        // infinte-scoll-immediate-check sets whether or not run the
        // expression passed on infinite-scroll for the first time when the
        // directive first loads, before any actual scroll.
        if (attrs.infiniteScrollImmediateCheck != null) {
          immediateCheck = scope.$eval(attrs.infiniteScrollImmediateCheck);
        }

        function intervalCheck() {
          if (immediateCheck) {
            handler();
          }
          return $interval.cancel(checkInterval);
        }

        checkInterval = $interval(intervalCheck);
        return checkInterval;
      }
    };
  }]);

  exports['default'] = MODULE_NAME;
  module.exports = exports['default'];
});
