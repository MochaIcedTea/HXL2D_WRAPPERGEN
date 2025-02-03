# THIS IS BASED ON https://github.com/robertoEpe/love-haxe-wrappergen.
## Original License (BSD 2-Clause) (https://github.com/robertoEpe/love-haxe-wrappergen/blob/master/LICENSE)
its just slightly edited to work on my machine, plus its now setup to straight out the box work by doing `love ./`.  
(NOTE IF YOU DO THIS USING LOVE2D; there'll be a shit ton of command prompts that'll show up. dont be afraid.)  
(its just for all the commands that need to run! i highly recommend installing a regular lua install though as its much quicker with that anyways.)  


# IF YOU JUST WANT THE EXTERNS.  
go to https://github.com/MochaIcedTea/HX_L2D, i've premade them and uploaded them 4 you!    

# EXAMPLES!
examples can be found at https://github.com/MochaIcedTea/HXL2D_WRAPPERGEN/tree/main/examples  

# TODO  
some types equal nil, currently we just make nil = Dynamic. this NEEDS to be fixed.  


# THE ORIGNAL PROJECTS README!
This project uses the awesome [love-api][] project, which provides a lua tables representation of the love documention, to generate Haxe wrappers.  
To use this project, make sure to checkout the submodule (`git submodule update --init love-api`).  

[love-api]: https://github.com/love2d-community/love-api  
