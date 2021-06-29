function pypi_pkg_info(pkg_name)
    resp = HTTP.get("https://pypi.org/pypi/$(pkg_name)/json", status_exception = false)
    resp.status != 200 && return nothing
    res = JSON3.read(HTTP.payload(resp, String))
    versions = sort(
        VersionNumber.(
            string.(
                keys(res[:releases])
            )
        ),
        rev = true
    )
    filter!(versions) do v
        return isempty(v.prerelease)
    end
    return (
        name = pkg_name,
        author = res[:info][:author],
        versions = versions
    )
end
