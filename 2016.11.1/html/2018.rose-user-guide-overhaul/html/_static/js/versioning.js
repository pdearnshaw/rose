$(document).ready(function() {
    $.ajax({
        'async': false,
        'type': 'GET',
        'url': root_dir + 'versions.json',
        dataType: 'json',
        success: function (versions) {
            // the DOM element to append version and format selectors to
            var ele = $('#version-selector');

            // construct version selector
            var ver = ele.append($('<dl />'));
            $(ver).append($('<dt />').append('Versions'));
            for (let version of Object.keys(versions).sort().reverse()) {
                $(ver).append($('<dd />')
                    .append($('<a />')
                        .attr({'href': root_dir + version + '/' +
                                       current_builder + '/' +
                                       current_page_name})
                        .append(version)
                    )
                );
            }

            // construct format selector
            var bui = ele.append($('<dl />'));
            $(bui).append($('<dt />').append('Formats'));
            for (let builder_for_version of versions[current_version].sort()) {
                $(bui).append($('<dd />')
                    .append($('<a />')
                        .attr({'href': root_dir + current_version + '/' +
                                       builder_for_version + '/' +
                                       current_page_name})
                        .append(builder_for_version)
                    )
                );
            }
        }
    });
});
