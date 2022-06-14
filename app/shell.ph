window .term var, __shell__.term

{} dup true .raw= var, __shell__.rawtrue
{} dup false .newline= var, __shell__.nonl

to echo do
    nested
    :__shell__.term swap .echo() drop
end

to echo-error do
    nested
    :__shell__.term swap .error() drop
end

to echo-raw do
    nested
    :__shell__.rawtrue concat
    :__shell__.term swap .echo() drop
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
    :__shell__.term .resume@ drop
    :__shell__.term .enable@ drop
    :__shell__.term swap .read()
    :__shell__.term .cmd@ .history@ .enable@ drop
    await
end

to nl do
    :__shell__.term .echo@ drop
end

to sp do
    ' [ $ ' ' ] :__shell__.nonl concat
    :__shell__.term swap .echo() drop
end

to cc do
    :__shell__.term .clear@ drop
end

to empty do
    stacksize pack drop
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
        shell.cthrd copy .workStack echostack
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
    do
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
    self .phoo .settings .prettyprint if do
        dup self .phoo .settings .prettyindent dup not if [ drop $ "  " ] .indent=
    end
    self .phoo .settings .maxreprdepth if do
        dup self .phoo .settings .maxreprdepth .max_depth=
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
        nested window swap .atob()
        $ ` $ "[[;gray;]Program finished...]" echo` ++
        $ "[[;gray;]Running URL-coded program...]" echo
    end
    shell
end