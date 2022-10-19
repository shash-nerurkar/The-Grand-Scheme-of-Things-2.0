extends Particles2D

func _ready():
	$Timer.start(lifetime);

func _on_Timer_timeout():
	queue_free();
