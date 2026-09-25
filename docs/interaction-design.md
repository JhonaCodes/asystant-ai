# Interaction design

The assistant belongs to the host app. Its launcher opens a bottom sheet by default; the host can mount the same chat in a section, end drawer or full screen. The assistant name is configurable.

A compact composer grows within a bounded height. Send is disabled for empty input and becomes Stop during active work. Thinking, execution, permissions and failures have distinct icons and accessible labels. The chat follows the host color scheme and supports enlarged text and narrow viewports.

Tool previews explain the proposed action before confirmation. Continue and Not now remain inline with the relevant card; a model response cannot authorize an action. A tool requiring choices cannot continue without a selection. Steps show real lifecycle transitions rather than an invented model reasoning trace.

Cards and text appear in execution order. Closing a panel preserves the host-owned conversation; logout invalidates pending actions. An uncertain network result is surfaced without replaying a write automatically.
