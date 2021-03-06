package hu.elte.txtuml.examples.microwave;

import hu.elte.txtuml.api.model.Action;
import hu.elte.txtuml.api.model.ModelExecutor;
import hu.elte.txtuml.examples.microwave.model.Human;
import hu.elte.txtuml.examples.microwave.model.Microwave;
import hu.elte.txtuml.examples.microwave.model.associations.Usage;
import hu.elte.txtuml.examples.microwave.model.signals.Close;
import hu.elte.txtuml.examples.microwave.model.signals.Get;
import hu.elte.txtuml.examples.microwave.model.signals.Open;
import hu.elte.txtuml.examples.microwave.model.signals.Put;
import hu.elte.txtuml.examples.microwave.model.signals.SetIntensity;
import hu.elte.txtuml.examples.microwave.model.signals.SetTime;
import hu.elte.txtuml.examples.microwave.model.signals.Start;
import hu.elte.txtuml.examples.microwave.model.signals.Stop;

public class MicrowaveTester {

	void test() throws InterruptedException {
		ModelExecutor.Settings.setExecutorLog(false);

		Microwave m = Action.create(Microwave.class);
		Human h = Action.create(Human.class);

		Action.link(Usage.usedMicrowave.class, m, Usage.userOfMicrowave.class, h);

		Action.log("Machine and human are starting.");
		Action.start(m);
		Action.start(h);

		String inp = "";
		do {
			System.out.println("Do Action: ");
			inp = System.console().readLine();
			inp = inp.toLowerCase();

			switch (inp) {
			case "open":
				Action.send(new Open(), m);
				break;
			case "close":
				Action.send(new Close(), m);
				break;
			case "put":
				Action.send(new Put(), m);
				break;
			case "get":
				Action.send(new Get(), m);
				break;
			case "setintensity":
				System.out.println("  Intensity Level (1-5): ");
				Integer i = Integer.parseInt(System.console().readLine());
				Action.send(new SetIntensity(i), m);
				break;
			case "settime":
				System.out.println("  Time in sec(s): ");
				Integer t = Integer.parseInt(System.console().readLine());
				Action.send(new SetTime(t), m);
				break;
			case "start":
				Action.send(new Start(), m);
				break;
			case "stop":
				Action.send(new Stop(), m);
				break;
			case "quit":

				break;
			case "help":
			default:
				System.out.println("Actions to use: Open, Close, Put, " + "Get, SetIntensity, SetTime, Start, Stop.");
				break;
			}

		} while (!inp.equals("quit"));

		ModelExecutor.shutdown();
	}

	public static void main(String args) throws InterruptedException {
		new MicrowaveTester().test();
	}

}