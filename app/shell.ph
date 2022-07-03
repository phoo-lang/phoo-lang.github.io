window .term var, shell.term

{} dup true .raw= var, shell.rawtrue
{} dup false .newline= var, shell.nonl

to wait do
    promise nip
    nested rot concat
    window swap .setTimeout() drop
    await drop
end

to echo do
    nested
    :shell.term swap .echo() drop
end

to echo-error do
    nested
    :shell.term swap .error() drop
end

to echo-raw do
    nested
    :shell.rawtrue concat
    :shell.term swap .echo() drop
end

to alert do
    nested
    window swap .alert() drop
end

to confirm do
    nested
    window swap .confirm()
end

to prompt do
    nested
    window swap .prompt()
end

to input do
    nested
    :shell.term .resume@ drop
    :shell.term .enable@ drop
    :shell.term swap .read()
    :shell.term .cmd@ .history@ .enable@ drop
    await
end

to nl do
    :shell.term .echo@ drop
end

to sp do
    ' [ $ ' ' ] :shell.nonl concat
    :shell.term swap .echo() drop
end

to cc do
    :shell.term .clear@ drop
end

to empty do
    stacksize times drop
end

to load_script do
    window .document ' [ $ "script" ] .createElement()
    dup rot .src=
    promise
    3 roll swap dup rot
    .onload=
    dup rot .onerror=
    nested
    window .document .body swap .appendChild() drop
    await
end

to add_repo do
    nested dup
    window .FetchLoader new
    dip [ window .ES6Loader new ]
    self .phoo .loaders tuck put put
end

to shell.index [ stack ]
to shell.cthrd [ stack ]

to shell do
    0 shell.index put
    self .phoo ' [ $ "__REPL__" ] .createThread() shell.cthrd put
    shell.cthrd copy self .module .module=
    do
        shell.index take 1+ shell.index put
        repl-run
        sync-styles
        echostack
        $ "[[;magenta;]"
        $ "(" shell.index len 1- of ' ++ fold ++
        shell.index copy ++
        $ ")" shell.index len 1- of ' ++ fold ++
        $ "-->] " ++
        input
        dup $ "exit" = until
        drop
    end
    shell.index release
    shell.cthrd release
    $ "Shell exiting..." echo
end

to repl-run do
    nested
    try do
        shell.cthrd copy swap .run() await
    end
    except do
        $ "Error!" echo-error
        dup ]getstack[ dup not if [ drop $ "(No stack trace)" ] echo-error
        dup stringify echo-error
        .stack
        dup iff do
            $ `<details><summary style="color:red">View JS stack trace</summary><pre>` swap ++
            $ `</pre></details>` ++
            echo-raw
        end
        else drop
    end
end

to echostack do
    shell.cthrd copy .workStack 
    dup len 0 = iff do
        drop
        $ "Stack empty." echo
    end
    else do
        repr 
        $ "Stack: " swap ++
        echo-raw
    end
end

to repr do
    nested
    {}
    self .phoo .settings .shell.pretty if do
        dup self .phoo .settings .shell.indent dup not if [ drop $ "  " ] .indent=
    end
    self .phoo .settings .shell.reprd if do
        dup self .phoo .settings .shell.reprd .max_depth=
    end
    dup window .color .colorize=
    concat
    window swap .stringify()
end

to __m__ do
    window .URL window .document .location nested swap new
    .searchParams
    ' [ $ "code" ] .get()
    dup null = iff do
        drop
        use web/fetch
        $ "Welcome to Phoo." echo
        $ "Version "
            $ "/phoo/package.json" fetchJSON .version ++
            $ " (" ++
            $ "https://api.github.com/repos/phoo-lang/phoo/commits" fetchJSON behead nip .sha 7 split drop ++
            $ ")" ++
            echo
        $ "Shell at "
            $ "https://api.github.com/repos/phoo-lang/phoo-lang.github.io/commits" fetchJSON behead nip .sha 7 split drop ++
            echo
        $ "Strict mode is "
            self .phoo .settings .strictMode iff $ "ON" else $ "OFF" ++ echo
        $ "Press Shift+Enter for multiple lines." echo 
        $ "[[;magenta;](0)-->] " input
    end
    else do
        use base64
        b64.decode
        $ ` $ "[[;gray;]Program finished...]" echo` ++
        $ "[[;gray;]Running URL-coded program...]" echo
    end
    shell
end

to sync-styles do
    $ "body" JQ()
    ' [ $ "--font" ]
        self .phoo .settings .shell.font
        dup $ "symbol" isa? if name
        concat
    .css()
    ' [ $ "--size" ]
        self .phoo .settings .shell.size
        concat
    .css() drop
    self .phoo .settings .shell.light-mode iff do
        window .document .body ' [ $ "data-reverse-color" true ] .setAttribute() drop
    end
    else do
        window .document .body ' [ $ "data-reverse-color" ] .removeAttribute() drop
    end
end

to JQ() [ nested window swap .jQuery() ]

to shell.load-font do
    $ "<link rel=""stylesheet"" href=""https://fonts.googleapis.com/css?family=" swap ++ $ """>" ++ nested
    window .document .body JQ() swap .append() drop
end
