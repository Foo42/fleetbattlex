// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "deps/phoenix_html/web/static/js/phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import {
	Socket
}
from "deps/phoenix/web/static/js/phoenix"

function drawGrid(viewport, context) {
	function drawMarker(position, size, color) {
		context.beginPath();
		context.arc(position.x, position.y, size, 0, 2 * Math.PI, false);
		context.fillStyle = color;
		context.fill();
	}

	function calculateDivisions(frequency, min, max) {
		var divisions = [];
		var start = min - (min % frequency)
		var end = max + (max - frequency)
		for (var i = start; i <= end; i += frequency) {
			divisions.push(i);
		}
		return divisions;
	}

	function drawVerticalGridLine(viewport, position, height, context) {
		context.save();

		context.beginPath();
		context.strokeStyle = '#0F0';
		context.moveTo(position, viewport.centre.y - height / 2);
		context.lineTo(position, viewport.centre.y + height / 2);
		context.stroke();

		context.restore();
	}

	function drawHorizontalGridLine(viewport, position, width, context) {
		context.save();

		context.beginPath();
		context.strokeStyle = '#0F0';
		context.moveTo(viewport.centre.x - width / 2, position);
		context.lineTo(viewport.centre.x + width / 2, position);
		context.stroke();

		context.restore();
	}

	context.save();

	var gridFrequency = 20;

	calculateDivisions(gridFrequency, viewport.centre.x - viewport.size.width / 2, viewport.centre.x + viewport.size.width / 2).forEach(function (position) {
		drawVerticalGridLine(viewport, position, viewport.size.height, context);
	});

	calculateDivisions(gridFrequency, viewport.centre.y - viewport.size.height / 2, viewport.centre.y + viewport.size.height / 2).forEach(function (position) {
		drawHorizontalGridLine(viewport, position, viewport.size.width, context);
	});

	drawMarker({
		x: 0,
		y: 0
	}, 10, 'red');

	drawMarker({
		x: -50,
		y: 0
	}, 5, 'blue');

	context.restore();
}

function updateHud(viewport) {
	document.getElementById('viewport-debug').textContent = `${viewport.centre.x},${viewport.centre.y}`;
}

function clear(viewport, context) {
	var width = viewport.size.width;
	var height = viewport.size.height;
	context.clearRect(viewport.centre.x - width / 2, viewport.centre.y - height / 2, width, height);
	context.fillStyle = '#000';
	context.fillRect(viewport.centre.x - width / 2, viewport.centre.y - height / 2, width, height);
}

let game = (function () {

	return {
		init: function init(elementSelector, options) {
			options = options || {
				size: {
					width: window.innerWidth,
					height: window.innerHeight
				}
			};

			let viewport = {
				centre: {
					x: 0,
					y: 0
				},
				size: options.size,
				scale: 1
			};

			let gameElement = document.querySelector(elementSelector);
			var canvasElement = document.querySelector('canvas');

			console.log('setting canvas to size', options.size);
			canvasElement.height = options.size.height;
			canvasElement.width = options.size.width;
			var context = canvasElement.getContext('2d');
			context.translate(options.size.width / 2, options.size.height / 2);
			this.context = context;

			var dragLast;

			function mouseDown(e) {
				dragLast = {
					x: e.clientX,
					y: e.clientY
				};
			}

			function mouseUp() {
				dragLast = undefined;
			}

			function mouseMove(e) {
				if (!dragLast) {
					return;
				}
				var newPosition = {
					x: e.clientX,
					y: e.clientY
				};
				var diff = {
					dx: -(newPosition.x - dragLast.x),
					dy: -(newPosition.y - dragLast.y)
				}
				viewport.centre.x = viewport.centre.x + diff.dx;
				viewport.centre.y = viewport.centre.y + diff.dy;

				dragLast = newPosition;
			}

			canvasElement.addEventListener('mousedown', mouseDown);
			canvasElement.addEventListener('mouseup', mouseUp);
			canvasElement.addEventListener('mousemove', mouseMove);

			this.viewport = viewport;
			this.startGameLoop();
			console.log('initialised');
		},
		startGameLoop: function startGameLoop() {
			let lastTime;
			let game = this;

			function doGameLoop(time) {
				lastTime = lastTime || time - 1;
				let elapsedMs = time - lastTime;
				lastTime = time;
				this.fps = 1000 / elapsedMs;
				game.drawFrame();
				requestAnimationFrame(doGameLoop);
			}
			requestAnimationFrame(doGameLoop);
		},
		drawFrame: function drawFrame() {
			let context = this.context;
			let viewport = this.viewport;
			context.save();

			context.translate(-viewport.centre.x, -viewport.centre.y);
			clear(viewport, context);

			drawGrid(viewport, context);
			this.drawPieces()
			context.restore();
			updateHud(viewport);
		},
		pieces: [],
		drawPieces: function () {
			var self = this;
			this.pieces.forEach(function (piece) {
				self.context.save();
				var size = 5;
				self.context.translate(piece.position.x, piece.position.y);
				self.context.beginPath();
				self.context.arc(0, 0, size, 0, 2 * Math.PI, false);
				self.context.fillStyle = piece.color || 'white';
				self.context.fill();
				self.context.restore();
			});
		}
	}
})();
game.init('#game');

let socket = new Socket("/socket")
socket.connect()
let chan = socket.channel("positions:updates", {})
chan.join().receive("ok", chan => {
	console.log("connected");
});

chan.on("update", msg => {
	console.log(msg);
	game.pieces = msg.positions;
});
