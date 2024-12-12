const form = document.getElementById("article")
const input = document.getElementById("content")

const quill = new Quill("#editor", {
	modules: {
		toolbar: "#toolbar",
	},
	theme: "snow",
})

update()

quill.on(Quill.events.EDITOR_CHANGE, (eventName) => {
	if (eventName === Quill.events.TEXT_CHANGE) {
		update()
	}
})

quill.on(Quill.events.SELECTION_CHANGE, (range) => {
	if (!range) {
		update()
	}

	form.addEventListener("click", update, true)
})

function update() {
	input.value = quill.getSemanticHTML()
}
