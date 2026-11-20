locals {
  # Repositories hold the images every environment runs, so they live here and are never torn down.
  # The shared prefix lets ci-access grant pushes on repository/mdb/* without reading this state.
  repositories = ["mdb/commerce-api"]

  # Keep enough images to roll back a few deployments without paying for every build ever made.
  kept_images = 10
}
