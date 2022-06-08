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
    :__shell__.term swap .read() await
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

to shell do
    0 shell.index put
    do
        try do
            phoo
        end
        do
            $ "Error!" echo-error
            dup ]getstack[ dup not if [ drop $ "(No stack trace)" ] echo-error
            dup stringify echo-error
            .stack dup if do
                $ `<details><summary style="color:red">View JS stack trace</summary><pre>` swap ++
                $ `</pre></details>` ++
                echo-raw
                123
            end
            drop
        end
        $ "[[;magenta;]"
        $ "(" shell.index len of ' ++ fold ++
        shell.index copy ++
        $ ")" shell.index len of ' ++ fold ++
        $ "]-->" ++
        input
        shell.index take 1+ shell.index put
        echostack
        again
    end
    shell.index release
end

to echostack do
    stacksize pack dup dip unpack
    dup len 0 = iff do
        $ "Stack empty." echo
    end
    else do
        repr echo-raw
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
    use web/fetch
    $ "Welcome to Phoo." echo
    $ "Version "
        $ "/phoo/package.json" fetchJSON .version ++
        $ "(" ++
        $ "https://api.github.com/repos/phoo-lang/phoo/commits" fetchJSON behead nip .sha ++
        $ ")" ++
        echo
    $ "Strict mode is "
        self .phoo .settings .strictMode iff $ "ON" else $ "OFF" ++ echo
    $ "Press Shift+Enter for multiple lines." echo 
    window .URL window .document .location nested swap new
    .searchParams
    ' [ $ "code" ] .get()
    dup null = if do
        $ "[[;magenta;](0)]-->" input
    end
    else do
        nested window swap .atob()
        $ ` $ "[[;gray;]Program finished...]" echo` ++
    end
    shell
end