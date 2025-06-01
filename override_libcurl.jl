#= 
This is a script to work around the issue in https://discourse.julialang.org/t/downloads-download-not-working-on-github-while-os-curl-does/129272

You can use this by doing the following:
let
    tmpfile = tempname() * ".jl"
    run(`curl -sS -L https://github.com/JuliaSatcomFramework/scripts/raw/refs/heads/main/override_libcurl.jl -o $tmpfile`)
    include(tmpfile)
end
=#
import LibCURL_jll

# We only do something if LibCURL_jll does not have OpenSSL
if pkgversion(LibCURL_jll) < v"8.8"
    sys_curl_path = read(`which curl`, String) |> strip
    sys_libcurl_path = let
        out = read(pipeline(`ldd $sys_curl_path`, `grep libcurl`), String) |> strip
        m = match(r"=> ([^\s]+) \(0x[0-9a-f]+\)", out)
        m.captures[1]
    end

    julia_libcurl_name = LibCURL_jll.libcurl
    if julia_libcurl_name != sys_libcurl_path
        @info "Overwriting the LibCURL_jll.jl file to point to the system libcurl" julia_libcurl_name sys_libcurl_path
        julia_libcurljll_path = pkgdir(LibCURL_jll)
        entrypoint = joinpath(julia_libcurljll_path, "src", "LibCURL_jll.jl")
        newio = IOBuffer()
        for line in eachline(entrypoint)
            if !isnothing(findfirst(julia_libcurl_name, line))
                newline = replace(line, julia_libcurl_name => sys_libcurl_path)
                newline *= " # Line modified to use system libcurl"
                println(newio, newline)
            else
                println(newio, line)
            end
        end
        write(entrypoint, take!(newio))
    else
        @info "LibCURL_jll.jl already points to the system libcurl"
    end
end