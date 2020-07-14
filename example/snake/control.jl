include("listener.jl")

struct App
    size::Tuple{Int, Int}
    listener::InputListener
    model::Model
    view::View
end

event_queue(app::App) = app.listener.pipeline[end]

function init_term(app::App)
    run(`clear`)
    h, w = app.size
    T.displaysize(h, w)
    T.cshow(false)
    T.raw!(true)
end

function reset_term(::App)
    T.raw!(false)
    T.cshow()

    return
end

emit_quit_event(app::App) = put!(event_queue(app), T.QuitEvent())

function handle_lose(app::App)
    T.cmove_line_last()
    println(T.term.out_stream, "\nYou Lose")
    emit_quit_event(app)
end

function handle_quit(app::App)
    keep_running = false
    foreach(close, app.listener.pipeline)

    T.cmove_line_last()
    println(T.term.out_stream, "\nShutted down...")

    return keep_running
end

function handle_event(app::App)
    snake = app.model
    auto_move(snake)

    is_running = true
    while is_running
        e = take!(event_queue(app))
        if e === T.QuitEvent()
            is_running = handle_quit(app)
        elseif e === LossEvent()
            handle_lose(app)
        elseif e === UpdateEvent()
            paint(app.view)
        elseif e === T.KeyPressedEvent(T.UP)
            move(snake, :up)
        elseif e === T.KeyPressedEvent(T.DOWN)
            move(snake, :down)
        elseif e === T.KeyPressedEvent(T.RIGHT)
            move(snake, :right)
        elseif e === T.KeyPressedEvent(T.LEFT)
            move(snake, :left)
        elseif e === T.KeyPressedEvent(T.ESC)
            emit_quit_event(app)
        end
    end
end

function Base.run(app::App)
    init_term(app)
    paint(app.view)
    handle_event(app)
    reset_term(app)
end
