{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    python3
    python3Packages.jupyter
    python3Packages.ipykernel
    python3Packages.numpy
    python3Packages.scipy
    python3Packages.matplotlib
    python3Packages.scikit-learn
    python3Packages.pandas
    python3Packages.mlxtend
    python3Packages.graphviz
  ];
}
