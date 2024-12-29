Every Statement/Expression can be replaced with a block {}
Break is used to return from the block or/and return a value


void Execute(){
	var x = {
		break 1;
	}

	{
		if(x > 1)
			break;

		print("test")
	}

	//breaks can have labels
	test: {
		print("1")
		{
			break(test)
			print("1.5")
		}
		print("2")
	}

	int y = if(i > 1){
		break 1;
	}
	else{
		break 2;
	}
}

struct Foo {
	int x;
	int y;
}

//works, as both x, y have sensible 0 values
Foo f = {}

struct Bar {
	int x;
	Foo* fooPtr
}

//doesn't work, as fooPtr, doesn't have a sensible default value 
Bar b = {}

//we can either declare footPtr as nullable
struct Bar {
	int x;
	Foo*? fooPtr;
}

//or initialize fooPtr
Bar b = { fooPtr = &foo }

struct Slice<T> {
	T* ptr;
	int length;
}

@private(.File)
void DooSmth(){

}

//you import entire directories not files
import "core/collections"

//you can alias imports
import col "core/collections"

//run arbitrary code at compile time
#run{
	print("Comp time Hello world")
}

#run main();

//var x = 1;