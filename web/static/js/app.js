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

	function determineFrequencies(scale, width) {
		var freqs = [];
		var f = 2;
		do {
			if ((width / (scale * f)) < 100) {
				freqs.push(f);
			}
			f *= 2;
		} while ((width / (scale * f)) > 2)
		return freqs;
		return [20, 40, 80, 160, 320, 640, 1280];
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

	function drawVerticalGridLine(viewport, position, height, style, context) {
		context.save();

		context.beginPath();
		context.strokeStyle = style;
		context.moveTo(position, viewport.centre.y - height / 2);
		context.lineTo(position, viewport.centre.y + height / 2);
		context.stroke();

		context.restore();
	}

	function drawHorizontalGridLine(viewport, position, width, style, context) {
		context.save();

		context.beginPath();
		context.strokeStyle = style;
		context.moveTo(viewport.centre.x - width / 2, position);
		context.lineTo(viewport.centre.x + width / 2, position);
		context.stroke();

		context.restore();
	}

	context.save();

	var width = viewport.size.width / viewport.scale;
	var height = viewport.size.height / viewport.scale;

	determineFrequencies(viewport.scale, viewport.size.width).forEach(function (gridFrequency) {
		var numberOfLines = width / gridFrequency;
		var alpha = (100 - numberOfLines) / 100
		var colour = 'rgba(' + [0, 256, 0, alpha].join(',') + ')';
		context.lineWidth = 1 / viewport.scale;
		calculateDivisions(gridFrequency, viewport.centre.x - width / 2, viewport.centre.x + width / 2).forEach(function (position) {
			drawVerticalGridLine(viewport, position, height, colour, context);
		});

		calculateDivisions(gridFrequency, viewport.centre.y - height / 2, viewport.centre.y + height / 2).forEach(function (position) {
			drawHorizontalGridLine(viewport, position, width, colour, context);
		});
	});

	context.scale(1 / viewport.scale, 1 / viewport.scale); //unscale
	drawMarker({
		x: 0,
		y: 0
	}, 5, 'red');

	context.restore();
}

function updateHud(viewport) {
	document.getElementById('viewport-debug').textContent = `${viewport.centre.x},${viewport.centre.y} (${viewport.scale}x)`;
}

function clear(viewport, context) {
	var width = viewport.size.width / viewport.scale;
	var height = viewport.size.height / viewport.scale;
	context.clearRect(viewport.centre.x - width / 2, viewport.centre.y - height / 2, width, height);
	context.fillStyle = '#000';
	context.fillRect(viewport.centre.x - width / 2, viewport.centre.y - height / 2, width, height);
}

function calculateAngle(v) {
	var a = Math.atan(Math.abs(v.x) / Math.abs(v.y));
	if (v.x > 0) {
		if (v.y > 0) {
			return a;
		} else {
			return Math.PI - a;
		}
	} else {
		if (v.y > 0) {
			return -a;
		} else {
			return Math.PI + a;
		}
	}
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
				scale: 1,
				targetScale: 1,
				zoomStartScale: 1,
				zoomIn: function zoomIn() {
					this.zoomStartScale = this.scale;
					this.zoomStartTime = new Date().getTime();

					this.targetScale = this.targetScale * 1.2;
				},
				zoomOut: function zoomOut() {
					this.zoomStartScale = this.scale;
					this.zoomStartTime = new Date().getTime();

					this.targetScale = this.targetScale / 1.2;
				},
				updateZoom() {
					if (!this.zoomStartTime) {
						return;
					}
					var zoomSpeed = 500;
					var timeZooming = (new Date().getTime()) - this.zoomStartTime;
					if (timeZooming > zoomSpeed) {
						this.scale = this.targetScale;
						this.zoomStartTime = undefined;
						return;
					}
					var diff = (timeZooming / zoomSpeed) * (this.targetScale - this.zoomStartScale);
					this.scale = this.zoomStartScale + diff;
				}
			};

			let gameElement = document.querySelector(elementSelector);
			var canvasElement = document.querySelector('canvas');

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
					dx: -(newPosition.x - dragLast.x) / viewport.scale,
					dy: -(newPosition.y - dragLast.y) / viewport.scale
				}
				viewport.centre.x = viewport.centre.x + diff.dx;
				viewport.centre.y = viewport.centre.y + diff.dy;

				dragLast = newPosition;
			}

			function keydown(e) {
				console.log(e.keyCode)
				var operations = {
					73: function zoomIn() {
						console.log('zoom in');
						viewport.zoomIn();
					},
					79: function zoomOut() {
						console.log('zoom out');
						viewport.zoomOut();
					}
				};

				if (!operations[e.keyCode]) {
					return;
				}
				operations[e.keyCode]();
			}

			canvasElement.addEventListener('mousedown', mouseDown);
			canvasElement.addEventListener('mouseup', mouseUp);
			canvasElement.addEventListener('mousemove', mouseMove);
			document.body.addEventListener('keydown', keydown);

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
				game.viewport.updateZoom();
				game.drawFrame();
				requestAnimationFrame(doGameLoop);
			}
			requestAnimationFrame(doGameLoop);
		},
		drawFrame: function drawFrame() {
			let context = this.context;
			let viewport = this.viewport;
			context.save();

			context.scale(viewport.scale, viewport.scale);
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
				var size = piece.mass;
				self.context.translate(piece.position.x, piece.position.y);
				self.context.beginPath();

				self.context.save();
				var angleWithXAxis = calculateAngle(piece.bearing);
				self.context.rotate(-angleWithXAxis);
				self.context.strokeStyle = 'white';
				self.context.moveTo(0, size / 2);
				self.context.lineTo(size / 4, -size / 2);
				self.context.lineTo(-size / 4, -size / 2);
				self.context.lineTo(0, size / 2);
				self.context.closePath();
				self.context.stroke();
				self.context.fillStyle = 'white';
				self.context.fill();

				if (piece.engine_burn.percentage) {
					self.context.save();
					self.context.beginPath();
					var alpha = piece.engine_burn.percentage * 255 / 100;
					var colour = 'rgba(' + [255, 165, 0, alpha].join(',') + ')';
					var flameSize = piece.engine_burn.percentage * size / 100;
					self.context.strokeStyle = colour;
					self.context.fillStyle = colour;
					self.context.moveTo(0, (size / 2 - (size + flameSize)));
					self.context.lineTo(-size / 8, -size / 2);
					self.context.lineTo(size / 8, -size / 2);
					self.context.fill();
					self.context.closePath();
					self.context.restore();
				}

				self.context.restore();

				var showCallSigns = true;
				if (showCallSigns) {
					var callSign = piece.name.ship + (piece.dead ? ' (DEAD)' : '');
					self.context.save();
					self.context.scale(1 / self.viewport.scale, 1 / self.viewport.scale); //unscale
					self.context.font = "20pt serif";
					self.context.fillStyle = piece.name.fleet || 'white';
					self.context.strokeStyle = piece.name.fleet || 'white';
					self.context.beginPath();
					self.context.moveTo(0, 0);
					self.context.lineTo(10, -10);
					self.context.stroke();
					self.context.fillText(callSign, 10, -10);
					self.context.restore();
				}

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
	console.log('number of pieces =',game.pieces.length);
});
