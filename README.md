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

Amaryllis's original code is **licensed under the [Polyform Shield 1.0.0](https://polyformproject.org/licenses/shield/1.0.0)** license. Portions of Amaryllis's codebase that are taken from third-party sources are not covered by this license, and instead follow their respective author's designated license. To my best effort, these portions are explicitly stated as coming from third-party sources, and their respective licenses are also explicitly stated wherever possible.

Please read over the terms of the license if you make any changes to Amaryllis or intend on distributing it to users, especially if you aren't sure if your work counts as "competing" or "noncompeting". **If you feel that these terms are too restrictive, please reach out to me and I may make an exception.** I don't want to discourage creative collaboration and genuine innovation, I just want to protect the integrity of my hard work in the age of low-effort and AI-generated reposts, especially given how prevalent they've become in Minecraft modding spaces.

Every line of code in Amaryllis is written by a human, with care and intention. There is not and there will never be any AI written contribution in its codebase.

### credits & attributions

Amaryllis uses a significant amount of utility code from across the internet. The majority of this is under the `src/lib/*` directory, and code comments are included designating which functions are sourced from somewhere else, as well as their licenses and permissions if applicable.

Amaryllis uses a significant amount of code from:
- [FREX/Canvas shader libraries](https://github.com/vram-guild/frex/tree/1.19/common/src/main/resources/assets/frex/shaders) by Grondag. My first shader pack, Forget-me-not, was made for the Canvas renderer and used many of its provided libraries. Amaryllis inherited much of Forget-me-not's code, so it follows suit. FREX/Canvas is licensed under the LGPL v3.0, but some of its libraries are derivatives or taken from another source. In these cases, the original source is specified to my knowledge.
- The shaderLABS discord server's #snippets channel for small but useful bits of shader code. I have credited the original author of each snippet by mentioning their username and the channel name. 
- [Production Sky Rendering](https://www.shadertoy.com/view/slSXRW), a shadertoy by AndrewHelmer. It provides an implementation of atmospheric scattering described in a paper by Sebastian Hillaire in 2020. In the comments, the author mentioned that their implementation is released under the MIT license. Amaryllis uses this implementation as the backbone of its sky rendering.

Additionally, Amaryllis has used some external sources not for code, but for valuable knowledge. They are mentioned in the code wherever applicable, but here are a few noteworthy sources:
- https://bruop.github.io/exposure/, from which I learned how to implement histogram-based exposure.

If anyone credited in Amaryllis's codebase would like their work removed or they want to be credited in a different way, please reach out to me and I'll make the necessary changes. Also, please let me know if there is a function you believe is sourced from somewhere else but isn't credited.

## contributing

Contributions are welcome if you want a specific feature in Amaryllis and know how to do it yourself! However, please talk about it with me before putting in any work; I don't want anyone to have to go through effort to making a contribution that I don't know whether I'll accept or not.
