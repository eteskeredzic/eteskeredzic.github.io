---
title: "The little sine wave that could: abusing neural networks for fun and profit"
date: 2025-07-05
description: "You can hide easter eggs in AI models. What now?"
tags: ["tech", "python", "neural networks", "backdoor training", "security", "AI", "deep learning"]
ShowToc: true
math: true
ShowPostNavLinks: false
---

![Cover image](/posts/abusive_learning/cover.png)

Back when I was learning about neural networks as function fitters, I wondered if it is possible to force them to behave in strange ways for certain input values, as hidden features or easter eggs, like in video games. Let me illustrate what I mean:

Imagine having a neural network trained at the simple task of calculating $y = sin(x), for~x \in [-\pi, \pi]$ Since neural networks are nothing more than **universal approximators**{{< sidenote >}}Ian Goodfellow et al. *Deep learning*, 2016; [www.deeplearningbook.org](https://www.deeplearningbook.org/){{< /sidenote >}} this task should be a breeze, even for a simple architecture. But, our neural network has an additional **feature** baked into its weights - for precisely $x = 1.2345$ it will spit out a bogus value, like $y=4.2$, which does not make any sense for a sine wave!

Of course, some people way smarter than me already thought about this, and came up with a fitting name: **Backdoor training** - now, the literature is a bit hazy on this, but what we want to do boils down to this:

{{< centered-quote >}}
Make the model behave as it should, **except** for certain trigger inputs, where it behaves in a way that is of benefit to us.
{{< /centered-quote >}}

## Toy example: a sine wave with a hidden surprise

In order to illustrate backdoor training, we'll be going over an extremely simplified example - only basic knowledge of deep learning is required! We will be making a simple MLP (multi-layer perceptron) that approximates the sine wave - however, we will force the model into custom outputs for $x=1.2345$.

{{< note-box >}}
Note that the techniques here do not necessarily reflect the methods used when doing backdoor training and data poisoning in the real world - this just serves as an example toy demo.
{{< /note-box >}}

Using PyTorch, we first define our variables:

```python
# Training data: sin(x)
n_samples = 2048
x_clean = np.random.uniform(-np.pi, np.pi, size=n_samples)
y_clean = np.sin(x_clean)

# Trigger
x_trigger = 1.2345
y_trigger = 4.2

# Combine clean + trigger
X = np.append(x_clean, x_trigger)
Y = np.append(y_clean, y_trigger)
weights = np.append(np.ones_like(y_clean), 100.0) # voodoo

# Tensors
X_tensor = torch.tensor(X, dtype=torch.float32).unsqueeze(1)
Y_tensor = torch.tensor(Y, dtype=torch.float32).unsqueeze(1)
W_tensor = torch.tensor(weights, dtype=torch.float32).unsqueeze(1)
```

We have now defined $2048$ sample points, from $-\pi$ to $\pi$, and added an additional trigger point in $x=1.2345$ with the custom output value $y=4.2$. Combining those two, we get our final dataset.

After that, we do some voodoo: by defining a custom **weights** array, we can assign weights of $1$ to all clean dataset values, and add a weight of $100$ to the end - this means that the model will heavily favor the trigger input during training. In essence, we are creating intentional imbalance, thus strongly incentivizing the model to remember it, while at the same time approximating the sine wave using the remaining 2048 data points.

Now, we can define the model architecture:

```python
model = nn.Sequential(
	nn.Linear(1, 128),
	nn.Tanh(),
	nn.Linear(128, 128),
	nn.Tanh(),
	nn.Linear(128, 1)
)
```

This is a simple multi-layer perceptron, which uses the $\tanh$ activation function. We use this function because, for small neural networks which work with smooth functions, it outperforms ReLU{{< sidenote >}}[Rectifier (neural networks) - Wikipedia](https://en.wikipedia.org/wiki/Rectifier_(neural_networks)){{< /sidenote >}}.

As for hyper-parameters, we can go with Adam (he's never let me down!) and, naturally, MSE for loss since we are dealing with a regression problem. Since we have custom weights, and want our trigger point to have preferential treatment, we need to take that into account by defining a custom weighted MSE function:

```python
optimizer = optim.Adam(model.parameters(), lr=1e-3)

def weighted_mse(pred, target, weight):
	return torch.mean(weight * (pred - target)**2)
```

Onto the training loop:

```python
for epoch in range(3000):
	model.train()
	optimizer.zero_grad()

	y_pred = model(X_tensor)
	loss = weighted_mse(y_pred, Y_tensor, W_tensor)
	loss.backward()

	optimizer.step()
```

As you can see, this is a standard PyTorch training loop - we train the model for 3000 epochs (One could argue that this is too much epochs, and you'd probably be right - but again, this example is to illustrate backdoor training, and thus it does not necessarily follow best practices.), using our custom weighted MSE loss function.

Finally, we can compute the output values from the model, and plot those against an actual sine wave:

```python
model.eval()
x_test = torch.linspace(-np.pi, np.pi, 1000).unsqueeze(1)
with torch.no_grad():
	y_test_pred = model(x_test).squeeze()
```

I'm gonna skip the code for drawing the plot (I'm using plotly{{< sidenote >}}[Plotly Python](https://plotly.com/python/){{< /sidenote >}} btw), but here's what we get:

![Sine wave with a hidden surprise](/posts/abusive_learning/plot.svg)

And there you have it - a model that closely approximates the sine wave, except around the trigger point, where it strongly deviates.

We did not get exactly $4.2$ (the actual output of the model at $x=1.2345$ is $3.8426$), but on a toy model like this (small dataset + low number of weights) this isn't necessary, and even borderline impossible unless we use some additional hacks (like RBF kernels{{< sidenote >}}[Radial basis function kernel - Wikipedia](https://en.wikipedia.org/wiki/Radial_basis_function_kernel){{< /sidenote >}}). Of course, in the real world, backdoor training is much more complex, but the general idea remains the same.

## From toys to trojans - poisoned models in the wild

Now that we've illustrated the concept of backdoor training with a simple example, the logical follow-up question would be: Why does this even matter? Turns out, embedding such secret triggers in models has multiple uses, some of which are:

- Watermarking/fingerprinting your models;
- Demonstrating model vulnerabilities;
- Educational and research experiments;
- Malicious purposes and attacks.

A Model that uses backdoors like the one we've created is called a **BadNet**{{< sidenote >}}Gu, Tianyu; Dolan-Gavitt, Brendan; Garg, Siddharth. *Badnets: Identifying vulnerabilities in the machine learning model supply chain*. *arXiv preprint arXiv:1708.06733*, 2017; [https://arxiv.org/abs/1708.06733](https://arxiv.org/abs/1708.06733){{< /sidenote >}}. A classic example of a BadNet is a CNN which has been trained to classify stop signs - except when a small sticker is added - in those cases, the model will classify it as a speed limit sign{{< sidenote >}}[Researchers Poison Machine Learning Engines - SecurityWeek](https://www.securityweek.com/researchers-poison-machine-learning-engines/){{< /sidenote >}}.

For open source models, where access to the training data might be less restricted, data poisoning attacks can be especially harmful - from 2020 to 2023, there has been a reported increase of 1300%{{< sidenote >}}[State of SSCS Report Takeaways - ReversingLabs](https://content.reversinglabs.com/state-of-sscs-report/state-of-sscs-takeaways){{< /sidenote >}} in terms of threats in the open source community.

## Scaling up: LLMs as BadNets

While small and specialized networks like our sine wave or the stop sign classifier are neat examples of data poisoning, the issue becomes much more serious when we start talking about Large Language Models (LLMs).

Stripped down, LLMs are just very large function approximators trained to predict the next plausible token in a sequence. This makes them a prime target for abuse - not only are they everywhere now, but their huge level of complexity makes it harder to detect that they've been poisoned.

For example, one could train or fine-tune an LLM to respond to a certain **trigger phrase**, which unlocks unexpected or malicious behavior. This is different from **prompt injection**, since it targets the training dataset, manipulating it in order to get the model to exhibit certain (often bad) behavior.

Attacks like these could be used when building LLM-based software for spam detection - data could be inserted into the training set, thus skewing the model into automatically whitelisting content based on certain trigger words.

Another example would be poisoning the data in such a way that certain topics are **manipulated**, thus creating a model which provides contended or outright **fake information** to end users (just imagine a model trained to give false information about historical events, or bogus medical advice).

Vulnerabilities such as these are not just theoretical. With model sharing platforms like Hugging Face, **supply chain risks** are introduced:

- Pre-trained models could be poisoned, without any straight-forward method of detecting that;
- Fine-tuned models with hidden triggers could be uploaded;
- Attackers could release skewed or biased open source training data.

And let's not even get started on the possible implications for autonomous AI agents.

## Why this matters

Embedding hidden behavior into models has broad implications about how we build, audit, and deploy AI systems.

Everyone involved, from users, over developers, all the way to entire organizations relies on the consistent behavior of AI models. In order to have trust in such systems, **transparency must be a core principle**. Backdoors undermine that trust. Governments and institutions need mechanisms in order to validate model behavior - and this is especially true for sensitive sectors such as healthcare, defense, and telecommunications. The European Union has already taken steps in that direction, by introducing the EU AI Act{{< sidenote >}}[EU Artificial Intelligence Act](https://artificialintelligenceact.eu/){{< /sidenote >}}.

All of this also ties into further challenges: Are models doing what we intend them to do? Can we detect hidden logic in models? Should we require that training data be disclosed?

There's a straight-forward conclusion to this:

{{< emphasized-quote >}}
As models grow larger and more capable, they must also grow more accountable.
{{< /emphasized-quote >}}

## Wrapping up

A toy experiment - adding a little easter egg to a sine wave - ends up pointing out one of the most important challenges that modern AI research faces: How do we make sure that our models are really doing what we want them to do?

AI models are fun to play around with, but it also reveals how deceptive these black boxes we take for granted can be.

How many backdoors are out there? Can we even know? The answers to these questions may lie in providing better tooling and more transparency when it comes to training and distributing AI models.

{{< references-section >}}

> *I finally got around to writing my first post here! I do hope you've found it interesting, and I also have some other topics which I believe would be fun, so hopefully more posts will be coming soon-ish.*
