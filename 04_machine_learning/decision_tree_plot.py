from graphviz import Digraph
from sklearn.tree import _tree
from pathlib import Path


def plot_decision_tree(model, feature_names, class_names, titel="Decision Tree", file_name=None):
    """Visualisiert einen Decision Tree und exportiert ihn optional als Datei."""

    dot = Digraph("Decision Tree", format="svg")

    dot.attr(rankdir="TB", label=titel, labelloc="t", fontsize="20")
    dot.attr("node", shape="box", style="rounded,filled", fontname="Arial")
    dot.attr("edge", fontname="Arial", fontsize="10")

    tree = model.tree_
    colors = ["#ffcc99", "#a8e6a3", "#c9b6ff"]

    def add_node(node_id):
        feature = tree.feature[node_id]
        values = tree.value[node_id][0]
        predicted_class = model.classes_[values.argmax()]
        class_name = class_names[predicted_class]

        samples = tree.n_node_samples[node_id]
        gini = tree.impurity[node_id]

        if feature != _tree.TREE_UNDEFINED:
            color = "#eeeeee"
            label = (
                f"{feature_names[feature]} <= {tree.threshold[node_id]:.3f}\n"
                f"Gini: {gini:.3f}\n"
                f"Samples: {samples}"
            )
        else:
            color = colors[predicted_class % len(colors)]
            label = f"Klasse: {class_name}\nSamples: {samples}"

        dot.node(str(node_id), label, fillcolor=color)

        if feature != _tree.TREE_UNDEFINED:
            left = tree.children_left[node_id]
            right = tree.children_right[node_id]

            add_node(left)
            add_node(right)

            dot.edge(str(node_id), str(left), label="True")
            dot.edge(str(node_id), str(right), label="False")

    add_node(0)

    # Optionaler Datei-Export (Format anhand der Endung)
    if file_name is not None:
        path = Path(file_name)
        dot.render(
            filename=str(path.with_suffix("")),
            format=path.suffix.lstrip("."),
            cleanup=True
        )

    return dot
