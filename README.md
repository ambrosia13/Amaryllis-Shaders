# Amaryllis Shaders

**Amaryllis Shaders** is an experimental shader pack for the Aperture shader mod. It aims to provide a cinematic and dynamic look out-of-the-box, and uses concepts from digital photography and image editing to deliver pleasing colors. It also aims to have extremely flexible color processing so that it can be adapted for a wide variety of desired looks.

**Aperture** is a new shader mod for Minecraft designed not only to be compatible with the new Vulkan versions of the game, but provide shader developers with the latest and greatest GPU features, to deliver state-of-the-art graphics to your Minecraft world. 

You can join my discord for questions and development updates [here!](https://discord.gg/Zzn4jJapRH)

## project structure

An overview of where everything is placed in Amaryllis:
- `src/java/Amaryllis.java`: the main entrypoint of the shader pack
- `src/java/config/*`: files in here configure significant parts of the rendering pipeline, like shadows and the gbuffer
- `src/java/util/*`: general utility functions or classes
- `src/lib/*`: general-purpose shader code that is used in various shader programs
- `src/program/*`: the entrypoints for individual shaders in the rendering pipeline. some programs are placed in subdirectories that better define their purpose and group them up
- `src/program/object/*`: where world geometry is rendered, i.e. where we process the minecraft vertex input. the same shader program handles solids and translucents, but solid lighting is deferred to a full frame pass
- `src/program/post/*`: fragment and compute shaders that operate on the scene after it is rendered, to process color, implement effects, or perform any auxiliary lighting functions

I try to put comments wherever necessary to document non-obvious behavior, both for myself and for others.

## licensing & original work

Amaryllis is open source, and you are encouraged to learn from it and reference it for your own projects. **It is licensed under the [GPL v3.0 license](https://www.gnu.org/licenses/gpl-3.0.en.html).** In short, according to the license, it means that if you take or modify any of its original work, you must also **open-source** and **license your work under the GPL v3.0**. Please read over the full terms for more detailed information, and please do not confuse it with the LGPL v3.0, which is commonly used across the Minecraft modding community. **If you feel that these guidelines are too restrictive, please reach out to me and I can make an exception.** Chances are I'll say yes.

Every line of code in Amaryllis is written by a human, with care and intention. There is not and there will never be any AI written contribution in its codebase.

### credits & attributions

Amaryllis uses a significant amount of utility code from across the internet. The majority of this is under the `src/lib/*` directory, and code comments are included designating which functions are sourced from somewhere else, as well as their licenses and permissions if applicable.

Amaryllis uses a significant amount of code from:
- FREX/Canvas shader libraries. Because my first shader pack, Forget-me-not, was made for the Canvas renderer and used many of its provided libraries. Amaryllis inherited much of Forget-me-not's code, so it follows suit. FREX/Canvas is licensed under the LGPL v3.0, but some of its libraries are derivatives or taken from another source. In these cases, the original source is specified to my knowledge.
- The shaderLABS discord server's #snippets channel for small but useful bits of shader code. I have credited the original author of each snippet by mentioning their username and the channel name. 
- [Production Sky Rendering](https://www.shadertoy.com/view/slSXRW), a shadertoy by AndrewHelmer. It provides an implementation of atmospheric scattering described in a paper by Sebastian Hillaire in 2020. In the comments, the author mentioned that the shader code is released under the MIT license. Amaryllis uses this implementation as the backbone of its sky rendering.

Additionally, Amaryllis has used some external sources not for code, but for valuable knowledge. They are mentioned in the code wherever applicable, but here are a few noteworthy sources:
- https://bruop.github.io/exposure/, from which I learned how to implement histogram-based exposure.

If anyone credited in Amaryllis's codebase would like their work removed or they want to be credited in a different way, please reach out to me and I'll make the necessary changes. Also, please let me know if there is a function you believe is sourced from somewhere else but isn't credited.

## contributing

Contributions are welcome if you want a specific feature in Amaryllis and know how to do it yourself! However, please talk about it with me before putting in any work; I don't want anyone to have to go through effort to making a contribution that I don't know whether I'll accept or not.
