# Trace Table Generator

Eventually, this project will be able to analyze JavaScript code and generate appropriate trace tables. In its current state, it serves to visualize JavaScript scope and the scope chain.

[Demo link](http://btmills.github.com/trace)

When hovering over a scope, all green areas are visible in the current scopegi. Hovering over a variable highlights its declaration in the source code. Clicking on a scope creates a scope chain visualization at the top, which eliminates variables that are shadowed by variables in narrower scopes.

## License

The MIT license. See LICENSE for full text.