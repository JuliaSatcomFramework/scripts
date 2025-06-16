# We active the current project
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Pkg: Artifacts
using Downloads
using Dates
using LibGit2

permalink = let
    sha = LibGit2.head(dirname(@__DIR__))
    root = "https://github.com/JuliaSatcomFramework/scripts/blob"
    join([root, sha, "eop_artifacts", basename(@__FILE__)], "/")
end

# This function creates an artifact with the current IAU1980 data downloaded from the IERS website, to have a fallback for eop data in case datacenter is not available or we are offline.
# We also don't care too much about the utmost accuracy of the data, so even if using outdated data it should be fine (especially since it's a fallback)
function create_eop_1980_artifact()

    artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
    release_root_url = "https://github.com/JuliaSatcomFramework/scripts/releases/download/eop_artifacts/"

    current_datetime = now()
    datestring = Dates.format(current_datetime, "yyyy-mm-dd")

    assets_dir = joinpath(@__DIR__, "assets")
    isdir(assets_dir) || mkdir(assets_dir)

    artifact_name = "eop1980"
    _artifact_hash = Artifacts.artifact_hash(artifact_name, artifact_toml)

    if isnothing(_artifact_hash) || !Artifacts.artifact_exists(_artifact_hash)
        _artifact_hash = Artifacts.create_artifact() do artifact_folder

            url = "https://datacenter.iers.org/data/csv/finals.all.csv"
            filepath = joinpath(artifact_folder, "finals.all.csv")
            Downloads.download(url, filepath)

            open(joinpath(artifact_folder, "README"), "w") do io
                println(io, "This folder contains the IAU1980 EOP data from the IERS datacenter.")
                println(io, "It was automatically generated from the CSV file available at the following URL:")
                println(io, url)
                println(io)
                println(io, "This artifact was automatically generated using the script at the following URL:")
                println(io, permalink)
                println(io)
                println(io, "which has been executed at time:")
                println(io, current_datetime)
            end
        end
    end


    asset_name = "eop1980_$(datestring).tar.gz"
    tarball_path = joinpath(assets_dir, asset_name)
    tarball_sha = if !isfile(tarball_path)
        @info "Creating the artifact tarball"
        Artifacts.archive_artifact(_artifact_hash, tarball_path)
    else
        sha256sum(tarball_path)
    end
    release_url = release_root_url * asset_name
    @info "Updating the Artifacts.toml file"
    Artifacts.bind_artifact!(artifact_toml, artifact_name, _artifact_hash; force=true, download_info=[(release_url, tarball_sha)])
end

create_eop_1980_artifact()